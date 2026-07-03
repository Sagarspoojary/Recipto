import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/receipt.dart';

/// Checks all active receipts for warranty expiry and sends email
/// notifications via the Receipto FastAPI backend.
///
/// Email is sent in two cases:
///   • 3 days before expiry  → reminder
///   • On or after expiry day → expired notice
///
/// SharedPreferences is used to ensure each email is sent ONLY ONCE
/// per receipt-per-type to avoid spamming the user.
class WarrantyEmailService {
  static const String _baseUrl = 'https://recipto.onrender.com';

  // SharedPrefs key prefixes
  static const String _prefix3Day  = 'warranty_3day_sent_';
  static const String _prefixExpiry = 'warranty_expiry_sent_';

  /// Call this on every app start / resume.
  /// [receipts] should be the full non-deleted list from Firestore.
  static Future<void> checkAndNotify(List<Receipt> receipts) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('WarrantyEmailService: No current user logged in.');
      return;
    }

    String? userEmail = user.email;
    if (userEmail == null || userEmail.isEmpty) {
      print('WarrantyEmailService: Auth email is empty, fetching from Firestore profile...');
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          userEmail = doc.data()?['email'] as String?;
        }
      } catch (e) {
        print('WarrantyEmailService: Error fetching Firestore profile email: $e');
      }
    }

    if (userEmail == null || userEmail.isEmpty) {
      print('WarrantyEmailService: User email is empty or null after Firestore check.');
      return;
    }

    print('WarrantyEmailService: Checking warranties for $userEmail. Total receipts: ${receipts.length}');
    final prefs = await SharedPreferences.getInstance();
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final receipt in receipts) {
      if (receipt.isDeleted) continue;
      if (receipt.warrantyExpiry == null) {
        print('WarrantyEmailService: Receipt ${receipt.merchant} has no warranty expiry date.');
        continue;
      }

      // Attempt to parse the warranty expiry date.
      final expiry = _parseDate(receipt.warrantyExpiry!);
      if (expiry == null) {
        print('WarrantyEmailService: Failed to parse warranty expiry date "${receipt.warrantyExpiry}" for merchant: ${receipt.merchant}');
        continue;
      }

      final expiryDay    = DateTime(expiry.year, expiry.month, expiry.day);
      final daysRemaining = expiryDay.difference(today).inDays;
      final receiptId    = receipt.receiptId;

      print('WarrantyEmailService: Receipt for "${receipt.merchant}" expires on ${receipt.warrantyExpiry} (Parsed: $expiryDay). Days remaining: $daysRemaining');

      final productNames = receipt.products
          .map((p) => p.name)
          .where((n) => n.isNotEmpty)
          .toList();

      // ── Day-countdown Reminders: 3 days, 2 days, 1 day ────────────────
      for (final reminderDay in [3, 2, 1]) {
        if (daysRemaining == reminderDay) {
          final key = '${_prefix3Day}${reminderDay}d_$receiptId';
          if (prefs.getBool(key) != true) {
            print('WarrantyEmailService: Sending $reminderDay-day reminder email to $userEmail for ${receipt.merchant}...');
            final sent = await _sendEmail(
              userEmail: userEmail,
              merchant: receipt.merchant,
              productNames: productNames,
              expiryDate: receipt.warrantyExpiry!,
              daysRemaining: reminderDay,
            );
            print('WarrantyEmailService: Email sent status: $sent');
            if (sent) {
              await prefs.setBool(key, true);
            }
          } else {
            print('WarrantyEmailService: $reminderDay-day reminder email already sent for receipt ID $receiptId.');
          }
        }
      }

      // ── Expiry Notification (on or after expiry day) ────────────────────
      if (daysRemaining <= 0) {
        final key = '$_prefixExpiry$receiptId';
        if (prefs.getBool(key) != true) {
          print('WarrantyEmailService: Sending expiry notification email to $userEmail for ${receipt.merchant}...');
          final sent = await _sendEmail(
            userEmail: userEmail,
            merchant: receipt.merchant,
            productNames: productNames,
            expiryDate: receipt.warrantyExpiry!,
            daysRemaining: daysRemaining,
          );
          print('WarrantyEmailService: Email sent status: $sent');
          if (sent) {
            await prefs.setBool(key, true);
          }
        } else {
          print('WarrantyEmailService: Expiry email already sent for receipt ID $receiptId.');
        }
      }
    }
  }

  /// Sends the warranty email via the Receipto FastAPI backend.
  /// Returns true on success.
  static Future<bool> _sendEmail({
    required String userEmail,
    required String merchant,
    required List<String> productNames,
    required String expiryDate,
    required int daysRemaining,
  }) async {
    try {
      final url = '$_baseUrl/send-warranty-email';
      print('WarrantyEmailService: Posting to $url...');
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_email':    userEmail,
          'merchant':      merchant,
          'product_names': productNames,
          'expiry_date':   expiryDate,
          'days_remaining': daysRemaining,
        }),
      ).timeout(const Duration(seconds: 20));

      print('WarrantyEmailService: Response status code: ${response.statusCode}, body: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('WarrantyEmailService: Error sending email request: $e');
      return false;
    }
  }

  /// Parses dates in YYYY-MM-DD, DD-MM-YYYY, or DD/MM/YYYY format.
  static DateTime? _parseDate(String raw) {
    // Standard ISO
    final iso = DateTime.tryParse(raw);
    if (iso != null) return iso;

    // DD-MM-YYYY or DD/MM/YYYY
    final parts = raw.split(RegExp(r'[-/]'));
    if (parts.length == 3) {
      final a = int.tryParse(parts[0]);
      final b = int.tryParse(parts[1]);
      final c = int.tryParse(parts[2]);
      if (a != null && b != null && c != null) {
        if (c > 1900) {
          // DD-MM-YYYY
          return DateTime.tryParse('$c-${b.toString().padLeft(2, '0')}-${a.toString().padLeft(2, '0')}');
        }
      }
    }
    return null;
  }
}
