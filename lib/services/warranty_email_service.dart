import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
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
    if (user == null) return;

    final userEmail = user.email;
    if (userEmail == null || userEmail.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final receipt in receipts) {
      if (receipt.isDeleted) continue;
      if (receipt.warrantyExpiry == null) continue;

      // Attempt to parse the warranty expiry date.
      // We support both ISO (YYYY-MM-DD) and DD-MM-YYYY / DD/MM/YYYY formats.
      final expiry = _parseDate(receipt.warrantyExpiry!);
      if (expiry == null) continue;

      final expiryDay    = DateTime(expiry.year, expiry.month, expiry.day);
      final daysRemaining = expiryDay.difference(today).inDays;
      final receiptId    = receipt.receiptId;

      final productNames = receipt.products
          .map((p) => p.name)
          .where((n) => n.isNotEmpty)
          .toList();

      // ── 3-Day Reminder ─────────────────────────────────────────────────
      if (daysRemaining == 3) {
        final key = '$_prefix3Day$receiptId';
        if (prefs.getBool(key) != true) {
          final sent = await _sendEmail(
            userEmail: userEmail,
            merchant: receipt.merchant,
            productNames: productNames,
            expiryDate: receipt.warrantyExpiry!,
            daysRemaining: 3,
          );
          if (sent) await prefs.setBool(key, true);
        }
      }

      // ── Expiry Notification (on or after expiry day) ────────────────────
      if (daysRemaining <= 0) {
        final key = '$_prefixExpiry$receiptId';
        if (prefs.getBool(key) != true) {
          final sent = await _sendEmail(
            userEmail: userEmail,
            merchant: receipt.merchant,
            productNames: productNames,
            expiryDate: receipt.warrantyExpiry!,
            daysRemaining: daysRemaining,
          );
          if (sent) await prefs.setBool(key, true);
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
      final response = await http.post(
        Uri.parse('$_baseUrl/send-warranty-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_email':    userEmail,
          'merchant':      merchant,
          'product_names': productNames,
          'expiry_date':   expiryDate,
          'days_remaining': daysRemaining,
        }),
      ).timeout(const Duration(seconds: 20));

      return response.statusCode == 200;
    } catch (_) {
      // Silent fail — we'll retry next time the app opens
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
