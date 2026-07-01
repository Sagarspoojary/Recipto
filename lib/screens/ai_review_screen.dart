import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/theme.dart';
import '../widgets/bento_card.dart';
import '../widgets/kinetic_typography.dart';
import '../widgets/particle_atmosphere.dart';

class AiReviewScreen extends StatefulWidget {
  final String jsonResult;
  const AiReviewScreen({Key? key, required this.jsonResult}) : super(key: key);

  @override
  State<AiReviewScreen> createState() => _AiReviewScreenState();
}

class _AiReviewScreenState extends State<AiReviewScreen> {
  late Map<String, dynamic> _data;
  final _formKey = GlobalKey<FormState>();

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
    'Travel',
    'Fuel',
    'Fashion',
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

    // Validate category selection
    final extractedCategory = _data['category']?.toString();
    _category = _categories.contains(extractedCategory) ? extractedCategory : 'Others';

    // Validate warranty selection
    final wMonths = _data['warrantyMonths'];
    if (wMonths is int && _warrantyOptions.contains(wMonths)) {
      _warrantyMonths = wMonths;
    } else {
      _warrantyMonths = null;
    }

    // Default products if missing
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
                            onPressed: () {
                              context.push('/scanner/ocr-placeholder');
                            },
                            child: Container(
                              height: 52,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  colors: [ReceiptoTheme.primary, ReceiptoTheme.secondary],
                                ),
                              ),
                              child: const Text(
                                'Continue',
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
                                    // Retake: pop back to scanner view
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
                                    // Pop back to scanner/processing to run AI again
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
