import 'dart:math';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/receipt.dart';

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<Receipt> processReceiptImage(String path, {bool isMock = false}) async {
    if (isMock) {
      return _generateMockReceiptResult();
    }

    try {
      final inputImage = InputImage.fromFilePath(path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      String merchant = 'Unknown Merchant';
      double total = 0.0;
      double tax = 0.0;
      DateTime date = DateTime.now();
      List<ReceiptItem> items = [];

      final lines = recognizedText.text.split('\n');
      if (lines.isNotEmpty) {
        merchant = lines[0].trim();
      }

      final priceRegex = RegExp(r'(\d+\.\d{2})');
      List<double> foundPrices = [];

      for (var line in lines) {
        final matches = priceRegex.allMatches(line);
        for (var match in matches) {
          final price = double.tryParse(match.group(0) ?? '0.0') ?? 0.0;
          if (price > 0 && !foundPrices.contains(price)) {
            foundPrices.add(price);
          }
        }
      }

      if (foundPrices.isNotEmpty) {
        foundPrices.sort();
        total = foundPrices.last;
        if (foundPrices.length > 1) {
          tax = foundPrices[foundPrices.length - 2] * 0.08;
        }
      }

      items.add(ReceiptItem(
        name: 'Scanned Purchase Item',
        brand: '',
        quantity: 1,
        unitPrice: total - tax,
        totalPrice: total - tax,
      ));

      return Receipt(
        receiptId: DateTime.now().millisecondsSinceEpoch.toString(),
        merchant: merchant.length > 25 ? merchant.substring(0, 25) : merchant,
        purchaseDate: date.toIso8601String().split('T')[0],
        purchaseTime: date.toIso8601String().split('T')[1].substring(0, 5),
        products: items,
        subtotal: total - tax,
        gst: double.parse(tax.toStringAsFixed(2)),
        discount: 0.0,
        total: total,
        currency: 'INR',
        category: _guessCategory(merchant),
        receiptImageUrl: path,
        paymentMethod: 'Card Scan',
        createdAt: DateTime.now(),
      );
    } catch (e) {
      return _generateMockReceiptResult();
    }
  }

  String _guessCategory(String merchant) {
    final m = merchant.toLowerCase();
    if (m.contains('starbucks') || m.contains('mcdonald') || m.contains('food') || m.contains('restaurant')) {
      return 'Restaurant';
    }
    if (m.contains('uber') || m.contains('airline') || m.contains('flight') || m.contains('hotel')) {
      return 'Travel';
    }
    if (m.contains('aws') || m.contains('google') || m.contains('microsoft') || m.contains('cloud')) {
      return 'Others';
    }
    if (m.contains('apple') || m.contains('best buy') || m.contains('electronics')) {
      return 'Electronics';
    }
    return 'Groceries';
  }

  Future<Receipt> _generateMockReceiptResult() async {
    await Future.delayed(const Duration(seconds: 2));
    final random = Random();
    final merchants = ['OpenAI', 'Starbucks', 'Apple Store', 'AWS Cloud', 'Uber', 'Shell Gas Station'];
    final selectedMerchant = merchants[random.nextInt(merchants.length)];
    
    double total = (30 + random.nextInt(150)) + random.nextDouble();
    total = double.parse(total.toStringAsFixed(2));
    double tax = double.parse((total * 0.0825).toStringAsFixed(2));

    List<ReceiptItem> items = [
      ReceiptItem(
        name: '$selectedMerchant Smart Premium Service',
        brand: '',
        quantity: 1,
        unitPrice: total - tax,
        totalPrice: total - tax,
      ),
    ];

    return Receipt(
      receiptId: DateTime.now().millisecondsSinceEpoch.toString(),
      merchant: selectedMerchant,
      purchaseDate: DateTime.now().toIso8601String().split('T')[0],
      products: items,
      subtotal: total - tax,
      gst: tax,
      discount: 0.0,
      total: total,
      currency: 'INR',
      category: _guessCategory(selectedMerchant),
      paymentMethod: 'Credit Card',
      createdAt: DateTime.now(),
    );
  }

  void dispose() {
    _textRecognizer.close();
  }
}
