import 'dart:convert';

class ReceiptItem {
  final String name;
  final double price;

  ReceiptItem({required this.name, required this.price});

  Map<String, dynamic> toMap() => {'name': name, 'price': price};
  factory ReceiptItem.fromMap(Map<String, dynamic> map) => ReceiptItem(
        name: map['name'] ?? '',
        price: (map['price'] as num?)?.toDouble() ?? 0.0,
      );
}

class Receipt {
  final String id;
  final String merchant;
  final DateTime date;
  final List<ReceiptItem> items;
  final double tax;
  final double discount;
  final double total;
  final String category;
  final double confidence;
  final String? imageUrl;
  final String paymentMethod;
  final String? notes;
  final bool isFavorite;
  final bool isArchived;

  Receipt({
    required this.id,
    required this.merchant,
    required this.date,
    required this.items,
    required this.tax,
    required this.discount,
    required this.total,
    required this.category,
    required this.confidence,
    this.imageUrl,
    required this.paymentMethod,
    this.notes,
    this.isFavorite = false,
    this.isArchived = false,
  });

  Receipt copyWith({
    String? id,
    String? merchant,
    DateTime? date,
    List<ReceiptItem>? items,
    double? tax,
    double? discount,
    double? total,
    String? category,
    double? confidence,
    String? imageUrl,
    String? paymentMethod,
    String? notes,
    bool? isFavorite,
    bool? isArchived,
  }) {
    return Receipt(
      id: id ?? this.id,
      merchant: merchant ?? this.merchant,
      date: date ?? this.date,
      items: items ?? this.items,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      category: category ?? this.category,
      confidence: confidence ?? this.confidence,
      imageUrl: imageUrl ?? this.imageUrl,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchant': merchant,
      'date': date.toIso8601String(),
      'items': items.map((x) => x.toMap()).toList(),
      'tax': tax,
      'discount': discount,
      'total': total,
      'category': category,
      'confidence': confidence,
      'imageUrl': imageUrl,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'isFavorite': isFavorite,
      'isArchived': isArchived,
    };
  }

  factory Receipt.fromMap(Map<String, dynamic> map) {
    return Receipt(
      id: map['id'] ?? '',
      merchant: map['merchant'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      items: List<ReceiptItem>.from(
          (map['items'] as List? ?? []).map((x) => ReceiptItem.fromMap(x))),
      tax: (map['tax'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] ?? 'Shopping',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 1.0,
      imageUrl: map['imageUrl'],
      paymentMethod: map['paymentMethod'] ?? 'Cash',
      notes: map['notes'],
      isFavorite: map['isFavorite'] ?? false,
      isArchived: map['isArchived'] ?? false,
    );
  }
}
