import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/receipt.dart';

abstract class ReceiptService {
  Stream<List<Receipt>> getReceiptsStream();
  Future<void> saveReceipt(Receipt receipt);
  Future<void> deleteReceipt(String id, String? imageUrl);
  Future<String> uploadReceiptImage(String receiptId, String localPath);
}

class FirestoreReceiptService implements ReceiptService {
  final SupabaseClient _client = Supabase.instance.client;
  final String userId;

  FirestoreReceiptService({required this.userId});

  Map<String, dynamic> _mapToSupabase(Receipt receipt) {
    return {
      'id': receipt.receiptId,
      'merchant': receipt.merchant,
      'invoice_number': receipt.invoiceNumber,
      'purchase_date': receipt.purchaseDate,
      'purchase_time': receipt.purchaseTime,
      'products': receipt.products.map((x) => x.toMap()).toList(),
      'subtotal': receipt.subtotal,
      'gst': receipt.gst,
      'discount': receipt.discount,
      'total': receipt.total,
      'currency': receipt.currency,
      'payment_method': receipt.paymentMethod,
      'category': receipt.category,
      'warranty_months': receipt.warrantyMonths,
      'warranty_expiry': receipt.warrantyExpiry,
      'merchant_phone': receipt.merchantPhone,
      'merchant_email': receipt.merchantEmail,
      'merchant_address': receipt.merchantAddress,
      'notes': receipt.notes,
      'image_url': receipt.receiptImageUrl,
      'user_id': userId,
      'created_at': receipt.createdAt?.toUtc().toIso8601String() ?? DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Receipt _mapFromSupabase(Map<String, dynamic> map) {
    return Receipt(
      receiptId: map['id'] ?? '',
      merchant: map['merchant'] ?? '',
      invoiceNumber: map['invoice_number'],
      purchaseDate: map['purchase_date'],
      purchaseTime: map['purchase_time'],
      products: List<ReceiptItem>.from(
          (map['products'] as List? ?? []).map((x) => ReceiptItem.fromMap(Map<String, dynamic>.from(x)))),
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      gst: (map['gst'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'INR',
      paymentMethod: map['payment_method'],
      category: map['category'] ?? 'Others',
      warrantyMonths: map['warranty_months'] is int ? map['warranty_months'] : (map['warranty_months'] as num?)?.toInt(),
      warrantyExpiry: map['warranty_expiry'],
      merchantPhone: map['merchant_phone'],
      merchantEmail: map['merchant_email'],
      merchantAddress: map['merchant_address'],
      notes: map['notes'],
      receiptImageUrl: map['image_url'],
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at']) : null,
      createdBy: map['user_id'],
    );
  }

  @override
  Stream<List<Receipt>> getReceiptsStream() {
    return _client
        .from('receipts')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((list) {
          return list.map((map) => _mapFromSupabase(map)).toList();
        });
  }

  @override
  Future<void> saveReceipt(Receipt receipt) async {
    await _client.from('receipts').upsert(_mapToSupabase(receipt));
  }

  @override
  Future<void> deleteReceipt(String id, String? imageUrl) async {
    // 1. Delete from database
    await _client.from('receipts').delete().eq('id', id);

    // 2. Delete from storage bucket if image exists
    if (imageUrl != null && imageUrl.contains('/storage/v1/object/public/receipts/')) {
      try {
        await _client.storage.from('receipts').remove(['$userId/$id.jpg']);
      } catch (e) {
        print('Error deleting storage image: $e');
      }
    }
  }

  @override
  Future<String> uploadReceiptImage(String receiptId, String localPath) async {
    final file = File(localPath);
    final storageRef = _client.storage.from('receipts');

    // Upload receipt image file
    await storageRef.upload(
      '$userId/$receiptId.jpg',
      file,
      fileOptions: const FileOptions(upsert: true),
    );

    return storageRef.getPublicUrl('$userId/$receiptId.jpg');
  }
}
