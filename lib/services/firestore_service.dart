import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/receipt.dart';

abstract class ReceiptService {
  Stream<List<Receipt>> getReceiptsStream();
  Future<void> saveReceipt(Receipt receipt);
  Future<void> deleteReceipt(String id, String? imageUrl);
  Future<String> uploadReceiptImage(String receiptId, String localPath);
}

class FirestoreReceiptService implements ReceiptService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String userId;

  FirestoreReceiptService({required this.userId});

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('users').doc(userId).collection('receipts');

  @override
  Stream<List<Receipt>> getReceiptsStream() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Ensure receiptId is bound from document ID if missing
        if (data['receiptId'] == null) {
          data['receiptId'] = doc.id;
        }
        return Receipt.fromMap(data);
      }).toList();
    });
  }

  @override
  Future<void> saveReceipt(Receipt receipt) async {
    await _collection.doc(receipt.receiptId).set(receipt.toMap());
  }

  @override
  Future<void> deleteReceipt(String id, String? imageUrl) async {
    // 1. Delete Firestore Document
    await _collection.doc(id).delete();

    // 2. Delete from Firebase Storage if URL exists and is a network storage path
    if (imageUrl != null && imageUrl.contains('firebasestorage.googleapis.com')) {
      try {
        final storageRef = _storage.refFromURL(imageUrl);
        await storageRef.delete();
      } catch (e) {
        // Log error and ignore if file does not exist in storage
        print('Error deleting storage image: $e');
      }
    }
  }

  @override
  Future<String> uploadReceiptImage(String receiptId, String localPath) async {
    final file = File(localPath);
    if (!await file.exists()) {
      throw Exception('Receipt image file not found at path: $localPath');
    }

    final storageRef = _storage.ref().child('receipts/$userId/$receiptId.jpg');
    final uploadTask = await storageRef.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }
}
