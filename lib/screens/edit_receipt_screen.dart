import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/theme.dart';
import '../models/receipt.dart';
import '../providers/receipt_provider.dart';
import '../widgets/bento_card.dart';
import '../widgets/kinetic_typography.dart';
import '../widgets/particle_atmosphere.dart';

class EditReceiptScreen extends ConsumerStatefulWidget {
  final Receipt receipt;
  const EditReceiptScreen({Key? key, required this.receipt}) : super(key: key);

  @override
  ConsumerState<EditReceiptScreen> createState() => _EditReceiptScreenState();
}

class _EditReceiptScreenState extends ConsumerState<EditReceiptScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  late List<Map<String, dynamic>> _products;

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
    _merchantController = TextEditingController(text: widget.receipt.merchant);
    _invoiceController = TextEditingController(text: widget.receipt.invoiceNumber);
    _dateController = TextEditingController(text: widget.receipt.purchaseDate);
    _timeController = TextEditingController(text: widget.receipt.purchaseTime);
    _subtotalController = TextEditingController(text: widget.receipt.subtotal.toString());
    _gstController = TextEditingController(text: widget.receipt.gst.toString());
    _discountController = TextEditingController(text: widget.receipt.discount.toString());
    _totalController = TextEditingController(text: widget.receipt.total.toString());
    _paymentController = TextEditingController(text: widget.receipt.paymentMethod);
    _notesController = TextEditingController(text: widget.receipt.notes);

    _category = _categories.contains(widget.receipt.category) ? widget.receipt.category : 'Others';
    _warrantyMonths = _warrantyOptions.contains(widget.receipt.warrantyMonths) ? widget.receipt.warrantyMonths : null;

    _products = widget.receipt.products.map((p) => {
      'name': p.name,
      'brand': p.brand ?? '',
      'quantity': p.quantity,
      'unitPrice': p.unitPrice,
      'totalPrice': p.totalPrice,
    }).toList();
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
      _products.add({
        'name': 'New Item',
        'brand': '',
        'quantity': 1,
        'unitPrice': 0.0,
        'totalPrice': 0.0,
      });
    });
  }

  void _removeProduct(int index) {
    setState(() {
      _products.removeAt(index);
    });
  }

  Future<void> _updateReceipt() async {
    if (_merchantController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a merchant name'), backgroundColor: ReceiptoTheme.error),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final productsList = _products.map((p) {
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

      final updatedReceipt = widget.receipt.copyWith(
        merchant: _merchantController.text.trim(),
        invoiceNumber: _invoiceController.text.trim().isEmpty ? null : _invoiceController.text.trim(),
        purchaseDate: _dateController.text.trim().isEmpty ? null : _dateController.text.trim(),
        purchaseTime: _timeController.text.trim().isEmpty ? null : _timeController.text.trim(),
        products: productsList,
        subtotal: double.tryParse(_subtotalController.text) ?? 0.0,
        gst: double.tryParse(_gstController.text) ?? 0.0,
        discount: double.tryParse(_discountController.text) ?? 0.0,
        total: double.tryParse(_totalController.text) ?? 0.0,
        paymentMethod: _paymentController.text.trim().isEmpty ? null : _paymentController.text.trim(),
        category: _category ?? 'Others',
        warrantyMonths: _warrantyMonths,
        warrantyExpiry: _warrantyMonths != null && _dateController.text.trim().isNotEmpty
            ? DateTime.tryParse(_dateController.text.trim())
                ?.add(Duration(days: _warrantyMonths! * 30))
                .toIso8601String().split('T')[0]
            : null,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        updatedAt: DateTime.now(),
      );

      // Save back to Firestore
      await ref.read(receiptServiceProvider).saveReceipt(updatedReceipt);

      if (mounted) {
        // Pop twice to return to dashboard with real-time update
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: ReceiptoTheme.error),
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
                            icon: const Icon(Icons.close_rounded, color: Colors.white70),
                            onPressed: () => context.pop(),
                          ),
                          const Text(
                            'Edit Receipt',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    // Scrollable fields
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
                                      itemCount: _products.length,
                                      separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                                      itemBuilder: (context, idx) {
                                        final prod = _products[idx];
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
                                    
                                    const Text('Category', style: TextStyle(fontSize: 10, color: Colors.white38)),
                                    const SizedBox(height: 6),
                                    _buildCategoryDropdown(),

                                    const SizedBox(height: 16),

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

                    // Actions Button
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _isSaving ? null : _updateReceipt,
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
                                  'Save Changes',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                                ),
                        ),
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
