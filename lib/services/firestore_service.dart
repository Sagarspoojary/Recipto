import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/receipt.dart';

abstract class ReceiptService {
  Future<List<Receipt>> getReceipts();
  Future<void> saveReceipt(Receipt receipt);
  Future<void> deleteReceipt(String id);
  Future<void> toggleFavorite(String id);
  Future<void> toggleArchive(String id);
}

class FirestoreReceiptService implements ReceiptService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String userId;

  FirestoreReceiptService({required this.userId});

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('users').doc(userId).collection('receipts');

  @override
  Future<List<Receipt>> getReceipts() async {
    final querySnapshot = await _collection.get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Receipt.fromMap(data);
    }).toList();
  }

  @override
  Future<void> saveReceipt(Receipt receipt) async {
    await _collection.doc(receipt.id).set(receipt.toMap());
  }

  @override
  Future<void> deleteReceipt(String id) async {
    await _collection.doc(id).delete();
  }

  @override
  Future<void> toggleFavorite(String id) async {
    final doc = await _collection.doc(id).get();
    if (doc.exists) {
      final current = doc.data()?['isFavorite'] ?? false;
      await _collection.doc(id).update({'isFavorite': !current});
    }
  }

  @override
  Future<void> toggleArchive(String id) async {
    final doc = await _collection.doc(id).get();
    if (doc.exists) {
      final current = doc.data()?['isArchived'] ?? false;
      await _collection.doc(id).update({'isArchived': !current});
    }
  }
}

class MockReceiptService implements ReceiptService {
  final List<Receipt> _receipts = [
    Receipt(
      id: '1',
      merchant: 'OpenAI',
      date: DateTime.now().subtract(const Duration(days: 1)),
      items: [
        ReceiptItem(name: 'ChatGPT Plus Subscription', price: 20.0),
        ReceiptItem(name: 'API Usage Credits', price: 80.0),
      ],
      tax: 0.0,
      discount: 0.0,
      total: 100.0,
      category: 'Subscriptions',
      confidence: 0.98,
      paymentMethod: 'Card (Visa)',
      isFavorite: true,
    ),
    Receipt(
      id: '2',
      merchant: 'Apple Store',
      date: DateTime.now().subtract(const Duration(days: 3)),
      items: [
        ReceiptItem(name: 'MacBook Pro 14" M4 Max', price: 3199.0),
        ReceiptItem(name: 'AppleCare+ Protection Plan', price: 399.0),
      ],
      tax: 287.84,
      discount: 150.0,
      total: 3735.84,
      category: 'Electronics',
      confidence: 0.99,
      paymentMethod: 'Apple Pay',
      isFavorite: true,
    ),
    Receipt(
      id: '3',
      merchant: 'Starbucks Coffee',
      date: DateTime.now().subtract(const Duration(hours: 4)),
      items: [
        ReceiptItem(name: 'Double Ristretto Venti Latte', price: 6.75),
        ReceiptItem(name: 'Gluten-Free Smoked Bacon Roll', price: 5.50),
      ],
      tax: 0.98,
      discount: 0.0,
      total: 13.23,
      category: 'Restaurant',
      confidence: 0.92,
      paymentMethod: 'Digital Wallet',
    ),
    Receipt(
      id: '4',
      merchant: 'Uber Technologies',
      date: DateTime.now().subtract(const Duration(days: 5)),
      items: [
        ReceiptItem(name: 'Uber Black Ride - Airport Transfer', price: 74.50),
        ReceiptItem(name: 'Driver Tip', price: 15.00),
      ],
      tax: 5.12,
      discount: 10.0,
      total: 84.62,
      category: 'Travel',
      confidence: 0.95,
      paymentMethod: 'Amex Card',
    ),
    Receipt(
      id: '5',
      merchant: 'AWS Cloud Services',
      date: DateTime.now().subtract(const Duration(days: 12)),
      items: [
        ReceiptItem(name: 'EC2 On-Demand Compute Instances', price: 142.10),
        ReceiptItem(name: 'S3 Standard Storage & Egress', price: 38.40),
        ReceiptItem(name: 'Amazon Aurora Serverless Cluster', price: 119.50),
      ],
      tax: 15.00,
      discount: 50.0,
      total: 265.00,
      category: 'Bills',
      confidence: 0.97,
      paymentMethod: 'Corporate Card',
    ),
  ];

  @override
  Future<List<Receipt>> getReceipts() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return List.from(_receipts);
  }

  @override
  Future<void> saveReceipt(Receipt receipt) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _receipts.indexWhere((r) => r.id == receipt.id);
    if (index >= 0) {
      _receipts[index] = receipt;
    } else {
      _receipts.add(receipt);
    }
  }

  @override
  Future<void> deleteReceipt(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _receipts.removeWhere((r) => r.id == id);
  }

  @override
  Future<void> toggleFavorite(String id) async {
    final index = _receipts.indexWhere((r) => r.id == id);
    if (index >= 0) {
      final current = _receipts[index];
      _receipts[index] = current.copyWith(isFavorite: !current.isFavorite);
    }
  }

  @override
  Future<void> toggleArchive(String id) async {
    final index = _receipts.indexWhere((r) => r.id == id);
    if (index >= 0) {
      final current = _receipts[index];
      _receipts[index] = current.copyWith(isArchived: !current.isArchived);
    }
  }
}
