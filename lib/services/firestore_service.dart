import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/receipt.dart';

abstract class ReceiptService {
  Stream<List<Receipt>> getReceiptsStream();
  Future<void> saveReceipt(Receipt receipt);
  Future<void> deleteReceipt(String id, String? imageUrl);
  Future<String> uploadReceiptImage(String receiptId, String localPath);
}

class FirestoreReceiptService implements ReceiptService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final String userId;

  FirestoreReceiptService({required this.userId});

  CollectionReference<Map<String, dynamic>> get _receiptsCollection =>
      _firestore.collection('users').doc(userId).collection('receipts');

  @override
  Stream<List<Receipt>> getReceiptsStream() {
    return _receiptsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Receipt.fromMap(doc.data()))
          .toList();
    });
  }

  @override
  Future<void> saveReceipt(Receipt receipt) async {
    await _receiptsCollection.doc(receipt.receiptId).set(
          receipt.toMap(),
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> deleteReceipt(String id, String? imageUrl) async {
    // 1. Delete from Firestore
    await _receiptsCollection.doc(id).delete();

    // 2. Delete from Supabase Storage if it contains the public URL path
    if (imageUrl != null && imageUrl.contains('/storage/v1/object/public/receipts/')) {
      try {
        await _supabase.storage.from('receipts').remove(['$userId/$id.jpg']);
      } catch (e) {
        print('Error deleting storage image from Supabase: $e');
      }
    }
  }

  @override
  Future<String> uploadReceiptImage(String receiptId, String localPath) async {
    final file = File(localPath);
    final storageRef = _supabase.storage.from('receipts');

    // Upload receipt image to Supabase Storage
    await storageRef.upload(
      '$userId/$receiptId.jpg',
      file,
      fileOptions: const FileOptions(upsert: true),
    );

    // Return the public URL of the uploaded image
    return storageRef.getPublicUrl('$userId/$receiptId.jpg');
  }
}
