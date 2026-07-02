import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/theme.dart';
import '../models/receipt.dart';
import '../providers/auth_provider.dart';
import '../providers/receipt_provider.dart';
import '../widgets/bento_card.dart';
import '../widgets/kinetic_typography.dart';
import '../widgets/particle_atmosphere.dart';

class AiReviewScreen extends ConsumerStatefulWidget {
  final String jsonResult;
  final String? filePath;

  const AiReviewScreen({
    Key? key,
    required this.jsonResult,
    this.filePath,
  }) : super(key: key);

  @override
  ConsumerState<AiReviewScreen> createState() => _AiReviewScreenState();
}

class _AiReviewScreenState extends ConsumerState<AiReviewScreen> {
  late Map<String, dynamic> _data;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Text Controllers
  late TextEditingController _merchantController;
  late TextEditingController _invoiceController;
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  late TextEditingController _subtotalController;
  late TextEditingController _gstController;
  late TextEditingController _discountController;
  late TextEditingController _totalController;
  late TextEditingController _paymentController;
  late TextEditingController _notesController;

  // Dropdown states
  String? _category;
  int? _warrantyMonths;

  final List<String> _categories = [
    'Electronics',
    'Groceries',
    'Restaurant',
    'Medical',
    'Fuel',
    'Fashion',
    'Travel',
    'Furniture',
    'Books',
    'Entertainment',
    'Home Appliances',
    'Others'
  ];

  final List<int?> _warrantyOptions = [null, 3, 6, 12, 24, 36];

  @override
  void initState() {
    super.initState();
    try {
      _data = jsonDecode(widget.jsonResult);
    } catch (_) {
      _data = {};
    }

    _merchantController = TextEditingController(text: _data['merchant']?.toString());
    _invoiceController = TextEditingController(text: _data['invoiceNumber']?.toString());
    _dateController = TextEditingController(text: _data['purchaseDate']?.toString());
    _timeController = TextEditingController(text: _data['purchaseTime']?.toString());
    _subtotalController = TextEditingController(text: _data['subtotal']?.toString() ?? '0.0');
    _gstController = TextEditingController(text: _data['gst']?.toString() ?? '0.0');
    _discountController = TextEditingController(text: _data['discount']?.toString() ?? '0.0');
    _totalController = TextEditingController(text: _data['total']?.toString() ?? '0.0');
    _paymentController = TextEditingController(text: _data['paymentMethod']?.toString());
    _notesController = TextEditingController(text: _data['notes']?.toString());

    final extractedCategory = _data['category']?.toString();
    _category = _categories.contains(extractedCategory) ? extractedCategory : 'Others';

    final wMonths = _data['warrantyMonths'];
    if (wMonths is int && _warrantyOptions.contains(wMonths)) {
      _warrantyMonths = wMonths;
    } else {
      _warrantyMonths = null;
    }

    if (_data['products'] == null) {
      _data['products'] = [];
    }
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _invoiceController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _subtotalController.dispose();
    _gstController.dispose();
    _discountController.dispose();
    _totalController.dispose();
    _paymentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addNewProduct() {
    setState(() {
      (_data['products'] as List).add({
        'name': 'New Product Item',
        'brand': '',
        'quantity': 1,
        'unitPrice': 0.0,
        'totalPrice': 0.0,
      });
    });
  }

  void _removeProduct(int index) {
    setState(() {
      (_data['products'] as List).removeAt(index);
    });
  }

  Future<void> _saveReceiptToFirebase() async {
    if (_merchantController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a merchant name'), backgroundColor: ReceiptoTheme.error),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    DateTime? parseCustomDate(String input) {
      final clean = input.trim();
      if (clean.isEmpty) return null;

      // 1. Try ISO YYYY-MM-DD
      final iso = DateTime.tryParse(clean);
      if (iso != null) return iso;

      // 2. Try DD-MM-YYYY
      final matchDash = RegExp(r'^(\d{1,2})-(\d{1,2})-(\d{4})$').firstMatch(clean);
      if (matchDash != null) {
        final d = int.parse(matchDash.group(1)!);
        final m = int.parse(matchDash.group(2)!);
        final y = int.parse(matchDash.group(3)!);
        return DateTime(y, m, d);
      }

      // 3. Try DD/MM/YYYY
      final matchSlash = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(clean);
      if (matchSlash != null) {
        final d = int.parse(matchSlash.group(1)!);
        final m = int.parse(matchSlash.group(2)!);
        final y = int.parse(matchSlash.group(3)!);
        return DateTime(y, m, d);
      }
      return null;
    }

    try {
      final receiptId = DateTime.now().millisecondsSinceEpoch.toString();
      final user = ref.read(authProvider).value;
      if (user == null) throw Exception("User not logged in");

      // 1. Upload receipt image to Firebase Storage (if local file path is available)
      String? imageUrl;
      if (widget.filePath != null && widget.filePath!.isNotEmpty && !widget.filePath!.endsWith('.pdf')) {
        imageUrl = await ref.read(receiptServiceProvider).uploadReceiptImage(receiptId, widget.filePath!);
      }

      // 2. Parse product rows
      final productsList = (_data['products'] as List).map((p) {
        final qty = p['quantity'] is int ? p['quantity'] : int.tryParse(p['quantity'].toString()) ?? 1;
        final unitPrice = p['unitPrice'] is double ? p['unitPrice'] : double.tryParse(p['unitPrice'].toString()) ?? 0.0;
        return ReceiptItem(
          name: p['name']?.toString() ?? '',
          brand: p['brand']?.toString(),
          quantity: qty,
          unitPrice: unitPrice,
          totalPrice: qty * unitPrice,
        );
      }).toList();

      final parsedPurchaseDate = parseCustomDate(_dateController.text);
      final purchaseDateStr = parsedPurchaseDate != null 
          ? parsedPurchaseDate.toIso8601String().split('T')[0]
          : (_dateController.text.trim().isEmpty ? null : _dateController.text.trim());

      // 3. Create Receipt Model
      final receipt = Receipt(
        receiptId: receiptId,
        merchant: _merchantController.text.trim(),
        invoiceNumber: _invoiceController.text.trim().isEmpty ? null : _invoiceController.text.trim(),
        purchaseDate: purchaseDateStr,
        purchaseTime: _timeController.text.trim().isEmpty ? null : _timeController.text.trim(),
        products: productsList,
        subtotal: double.tryParse(_subtotalController.text) ?? 0.0,
        gst: double.tryParse(_gstController.text) ?? 0.0,
        discount: double.tryParse(_discountController.text) ?? 0.0,
        total: double.tryParse(_totalController.text) ?? 0.0,
        currency: 'INR',
        paymentMethod: _paymentController.text.trim().isEmpty ? null : _paymentController.text.trim(),
        category: _category ?? 'Others',
        warrantyMonths: _warrantyMonths,
        warrantyExpiry: _warrantyMonths != null && parsedPurchaseDate != null
            ? parsedPurchaseDate.add(Duration(days: _warrantyMonths! * 30)).toIso8601String().split('T')[0]
            : null,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        receiptImageUrl: imageUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: user.uid,
      );

      // 4. Save to Firestore
      await ref.read(receiptServiceProvider).saveReceipt(receipt);

      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Save Error', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.grey[900],
            content: Text('Failed to save receipt: $e', style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(color: ReceiptoTheme.secondary)),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ParticleAtmosphere(
        child: Stack(
          children: [
            const Positioned.fill(child: KineticTypography()),
            SafeArea(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
                            onPressed: () => context.pop(),
                          ),
                          const Text(
                            'AI Receipt Review',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    // Scrollable Fields
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            // Merchant Info Card
                            BentoCard(
                              glowColor: ReceiptoTheme.primary,
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('MERCHANT & BILL DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white60, letterSpacing: 1.5)),
                                    const SizedBox(height: 16),
                                    _buildEditableField('Merchant Name', _merchantController, Icons.storefront_rounded),
                                    const SizedBox(height: 12),
                                    _buildEditableField('Invoice Number', _invoiceController, Icons.receipt_rounded),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(child: _buildEditableField('Date', _dateController, Icons.calendar_today_rounded)),
                                        const SizedBox(width: 12),
                                        Expanded(child: _buildEditableField('Time', _timeController, Icons.access_time_rounded)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Products list
                            BentoCard(
                              glowColor: ReceiptoTheme.secondary,
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('ITEMS LIST', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white60, letterSpacing: 1.5)),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline_rounded, color: ReceiptoTheme.secondary),
                                          onPressed: _addNewProduct,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: (_data['products'] as List).length,
                                      separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                                      itemBuilder: (context, idx) {
                                        final prod = (_data['products'] as List)[idx];
                                        return _buildProductRow(prod, idx);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Classification & Financials
                            BentoCard(
                              glowColor: Colors.transparent,
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('CLASSIFICATION & TOTALS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white60, letterSpacing: 1.5)),
                                    const SizedBox(height: 16),
                                    
                                    // Category Dropdown
                                    const Text('Category', style: TextStyle(fontSize: 10, color: Colors.white38)),
                                    const SizedBox(height: 6),
                                    _buildCategoryDropdown(),

                                    const SizedBox(height: 16),

                                    // Warranty Dropdown
                                    const Text('Warranty Period', style: TextStyle(fontSize: 10, color: Colors.white38)),
                                    const SizedBox(height: 6),
                                    _buildWarrantyDropdown(),

                                    const SizedBox(height: 16),

                                    Row(
                                      children: [
                                        Expanded(child: _buildEditableField('Subtotal', _subtotalController, Icons.money_rounded, keyboardType: TextInputType.number)),
                                        const SizedBox(width: 12),
                                        Expanded(child: _buildEditableField('GST/Tax', _gstController, Icons.gavel_rounded, keyboardType: TextInputType.number)),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(child: _buildEditableField('Discount', _discountController, Icons.percent_rounded, keyboardType: TextInputType.number)),
                                        const SizedBox(width: 12),
                                        Expanded(child: _buildEditableField('Grand Total', _totalController, Icons.payments_rounded, keyboardType: TextInputType.number)),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _buildEditableField('Payment Method', _paymentController, Icons.account_balance_wallet_rounded),
                                    const SizedBox(height: 12),
                                    _buildEditableField('Notes', _notesController, Icons.note_alt_rounded),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),

                    // Bottom navigation action buttons
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: _isSaving ? null : _saveReceiptToFirebase,
                            child: Container(
                              height: 52,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  colors: [ReceiptoTheme.primary, ReceiptoTheme.secondary],
                                ),
                              ),
                              child: _isSaving
                                  ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white))
                                  : const Text(
                                      'Save Receipt',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.white.withOpacity(0.12)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  onPressed: () {
                                    context.pop();
                                  },
                                  child: const Text('Retake', style: TextStyle(color: Colors.white70)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.white.withOpacity(0.12)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  onPressed: () {
                                    context.pop();
                                  },
                                  child: const Text('Run AI Again', style: TextStyle(color: Colors.white70)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType}) {
    final isFieldEmpty = controller.text.trim().isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: (val) {
            setState(() {});
          },
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: isFieldEmpty ? Colors.amber : ReceiptoTheme.secondary, size: 18),
            hintText: 'Not Detected',
            hintStyle: TextStyle(color: Colors.amber.withOpacity(0.6), fontSize: 13),
            filled: true,
            fillColor: Colors.white.withOpacity(0.02),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isFieldEmpty ? Colors.amber.withOpacity(0.5) : Colors.white.withOpacity(0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isFieldEmpty ? Colors.amber : ReceiptoTheme.secondary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _category,
          dropdownColor: Colors.black.withOpacity(0.95),
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white60),
          isExpanded: true,
          items: _categories.map((cat) {
            return DropdownMenuItem<String>(
              value: cat,
              child: Text(cat),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _category = val;
            });
          },
        ),
      ),
    );
  }

  Widget _buildWarrantyDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _warrantyMonths,
          dropdownColor: Colors.black.withOpacity(0.95),
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white60),
          isExpanded: true,
          items: _warrantyOptions.map((opt) {
            return DropdownMenuItem<int?>(
              value: opt,
              child: Text(opt == null ? 'No Warranty' : '$opt Months'),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _warrantyMonths = val;
            });
          },
        ),
      ),
    );
  }

  Widget _buildProductRow(Map<String, dynamic> product, int index) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Item Name', style: TextStyle(fontSize: 9, color: Colors.white30)),
                  const SizedBox(height: 4),
                  TextFormField(
                    initialValue: product['name']?.toString(),
                    onChanged: (val) => product['name'] = val,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: ReceiptoTheme.error, size: 20),
              onPressed: () => _removeProduct(index),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Brand', style: TextStyle(fontSize: 9, color: Colors.white30)),
                  const SizedBox(height: 4),
                  TextFormField(
                    initialValue: product['brand']?.toString(),
                    onChanged: (val) => product['brand'] = val,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Qty', style: TextStyle(fontSize: 9, color: Colors.white30)),
                  const SizedBox(height: 4),
                  TextFormField(
                    initialValue: product['quantity']?.toString() ?? '1',
                    keyboardType: TextInputType.number,
                    onChanged: (val) => product['quantity'] = int.tryParse(val) ?? 1,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Price', style: TextStyle(fontSize: 9, color: Colors.white30)),
                  const SizedBox(height: 4),
                  TextFormField(
                    initialValue: product['unitPrice']?.toString() ?? '0.0',
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      final parsedPrice = double.tryParse(val) ?? 0.0;
                      product['unitPrice'] = parsedPrice;
                      product['totalPrice'] = (product['quantity'] ?? 1) * parsedPrice;
                    },
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
