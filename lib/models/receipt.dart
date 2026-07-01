class ReceiptItem {
  final String name;
  final String? brand;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  ReceiptItem({
    required this.name,
    this.brand,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'brand': brand,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'totalPrice': totalPrice,
      };

  factory ReceiptItem.fromMap(Map<String, dynamic> map) => ReceiptItem(
        name: map['name'] ?? '',
        brand: map['brand'],
        quantity: map['quantity'] is int ? map['quantity'] : (map['quantity'] as num?)?.toInt() ?? 1,
        unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
        totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
      );
}

class Receipt {
  final String receiptId;
  final String merchant;
  final String? invoiceNumber;
  final String? purchaseDate;
  final String? purchaseTime;
  final List<ReceiptItem> products;
  final double subtotal;
  final double gst;
  final double discount;
  final double total;
  final String currency;
  final String? paymentMethod;
  final String category;
  final int? warrantyMonths;
  final String? warrantyExpiry;
  final String? merchantPhone;
  final String? merchantEmail;
  final String? merchantAddress;
  final String? notes;
  final String? receiptImageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  Receipt({
    required this.receiptId,
    required this.merchant,
    this.invoiceNumber,
    this.purchaseDate,
    this.purchaseTime,
    required this.products,
    required this.subtotal,
    required this.gst,
    required this.discount,
    required this.total,
    required this.currency,
    this.paymentMethod,
    required this.category,
    this.warrantyMonths,
    this.warrantyExpiry,
    this.merchantPhone,
    this.merchantEmail,
    this.merchantAddress,
    this.notes,
    this.receiptImageUrl,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  Receipt copyWith({
    String? receiptId,
    String? merchant,
    String? invoiceNumber,
    String? purchaseDate,
    String? purchaseTime,
    List<ReceiptItem>? products,
    double? subtotal,
    double? gst,
    double? discount,
    double? total,
    String? currency,
    String? paymentMethod,
    String? category,
    int? warrantyMonths,
    String? warrantyExpiry,
    String? merchantPhone,
    String? merchantEmail,
    String? merchantAddress,
    String? notes,
    String? receiptImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return Receipt(
      receiptId: receiptId ?? this.receiptId,
      merchant: merchant ?? this.merchant,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchaseTime: purchaseTime ?? this.purchaseTime,
      products: products ?? this.products,
      subtotal: subtotal ?? this.subtotal,
      gst: gst ?? this.gst,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      category: category ?? this.category,
      warrantyMonths: warrantyMonths ?? this.warrantyMonths,
      warrantyExpiry: warrantyExpiry ?? this.warrantyExpiry,
      merchantPhone: merchantPhone ?? this.merchantPhone,
      merchantEmail: merchantEmail ?? this.merchantEmail,
      merchantAddress: merchantAddress ?? this.merchantAddress,
      notes: notes ?? this.notes,
      receiptImageUrl: receiptImageUrl ?? this.receiptImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'receiptId': receiptId,
      'merchant': merchant,
      'invoiceNumber': invoiceNumber,
      'purchaseDate': purchaseDate,
      'purchaseTime': purchaseTime,
      'products': products.map((x) => x.toMap()).toList(),
      'subtotal': subtotal,
      'gst': gst,
      'discount': discount,
      'total': total,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'category': category,
      'warrantyMonths': warrantyMonths,
      'warrantyExpiry': warrantyExpiry,
      'merchantPhone': merchantPhone,
      'merchantEmail': merchantEmail,
      'merchantAddress': merchantAddress,
      'notes': notes,
      'receiptImageUrl': receiptImageUrl,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  factory Receipt.fromMap(Map<String, dynamic> map) {
    return Receipt(
      receiptId: map['receiptId'] ?? '',
      merchant: map['merchant'] ?? '',
      invoiceNumber: map['invoiceNumber'],
      purchaseDate: map['purchaseDate'],
      purchaseTime: map['purchaseTime'],
      products: List<ReceiptItem>.from(
          (map['products'] as List? ?? []).map((x) => ReceiptItem.fromMap(x))),
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      gst: (map['gst'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'INR',
      paymentMethod: map['paymentMethod'],
      category: map['category'] ?? 'Others',
      warrantyMonths: map['warrantyMonths'] is int ? map['warrantyMonths'] : (map['warrantyMonths'] as num?)?.toInt(),
      warrantyExpiry: map['warrantyExpiry'],
      merchantPhone: map['merchantPhone'],
      merchantEmail: map['merchantEmail'],
      merchantAddress: map['merchantAddress'],
      notes: map['notes'],
      receiptImageUrl: map['receiptImageUrl'],
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt']) : null,
      createdBy: map['createdBy'],
    );
  }
}
