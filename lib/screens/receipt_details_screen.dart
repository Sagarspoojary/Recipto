import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/theme.dart';
import '../models/receipt.dart';
import '../providers/receipt_provider.dart';
import '../widgets/bento_card.dart';
import '../widgets/kinetic_typography.dart';
import '../widgets/particle_atmosphere.dart';

class ReceiptDetailsScreen extends ConsumerWidget {
  final Receipt receipt;
  const ReceiptDetailsScreen({Key? key, required this.receipt}) : super(key: key);

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[950],
        title: const Text('Delete Receipt?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'This action will permanently delete the Firestore document and the original uploaded receipt image from Storage.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white50)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Pop dialog
              try {
                final service = ref.read(receiptServiceProvider);
                await service.deleteReceipt(receipt.receiptId, receipt.receiptImageUrl);
                if (context.mounted) {
                  context.pop(); // Pop details screen back to dashboard
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e'), backgroundColor: ReceiptoTheme.error),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: ReceiptoTheme.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasWarranty = receipt.warrantyExpiry != null;

    return Scaffold(
      body: ParticleAtmosphere(
        child: Stack(
          children: [
            const Positioned.fill(child: KineticTypography()),
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Toolbar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
                          onPressed: () => context.pop(),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: Colors.white),
                              onPressed: () {
                                context.push('/receipt/edit', extra: receipt);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: ReceiptoTheme.error),
                              onPressed: () => _showDeleteConfirmation(context, ref),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Receipt Image Section (if available)
                    if (receipt.receiptImageUrl != null && receipt.receiptImageUrl!.isNotEmpty) ...[
                      BentoCard(
                        glowColor: ReceiptoTheme.secondary.withOpacity(0.3),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.network(
                                receipt.receiptImageUrl!,
                                height: 220,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                loadingBuilder: (_, child, progress) {
                                  if (progress == null) return child;
                                  return const SizedBox(
                                    height: 220,
                                    child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(ReceiptoTheme.secondary))),
                                  );
                                },
                              ),
                              Positioned(
                                bottom: 12,
                                right: 12,
                                child: CircleAvatar(
                                  backgroundColor: Colors.black.withOpacity(0.6),
                                  child: IconButton(
                                    icon: const Icon(Icons.fullscreen_rounded, color: Colors.white),
                                    onPressed: () {
                                      _showFullscreenImage(context, receipt.receiptImageUrl!);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Merchant Overview Bento
                    BentoCard(
                      glowColor: ReceiptoTheme.primary,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Text(
                              receipt.merchant.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Invoice: ${receipt.invoiceNumber ?? "Not Provided"}',
                              style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5)),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '₹${receipt.total.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Products Table Bento
                    BentoCard(
                      glowColor: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ITEMIZED PRODUCTS', style: TextStyle(fontSize: 9, letterSpacing: 1.5, color: Colors.white54, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            if (receipt.products.isEmpty)
                              const Text('No products extracted.', style: TextStyle(fontSize: 12, color: Colors.white30))
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: receipt.products.length,
                                separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 16),
                                itemBuilder: (context, idx) {
                                  final p = receipt.products[idx];
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(p.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                            if (p.brand != null && p.brand!.isNotEmpty)
                                              Text('Brand: ${p.brand}', style: const TextStyle(fontSize: 9, color: Colors.white38)),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${p.quantity}x ₹${p.unitPrice.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        '₹${p.totalPrice.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ],
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Financial summary
                    BentoCard(
                      glowColor: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('FINANCIAL SUMMARY', style: TextStyle(fontSize: 9, letterSpacing: 1.5, color: Colors.white54, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            _buildSummaryRow('Subtotal', '₹${receipt.subtotal.toStringAsFixed(2)}'),
                            _buildSummaryRow('GST/Tax', '₹${receipt.gst.toStringAsFixed(2)}'),
                            _buildSummaryRow('Discount', '-₹${receipt.discount.toStringAsFixed(2)}'),
                            const Divider(height: 24, color: Colors.white12),
                            _buildSummaryRow('Grand Total', '₹${receipt.total.toStringAsFixed(2)}', isBold: true),
                            const SizedBox(height: 8),
                            _buildSummaryRow('Payment Method', receipt.paymentMethod ?? 'Not Provided', isMuted: true),
                            _buildSummaryRow('Category', receipt.category, isMuted: true),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Warranty & Store Contact Bento
                    BentoCard(
                      glowColor: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ADDITIONAL INFORMATION', style: TextStyle(fontSize: 9, letterSpacing: 1.5, color: Colors.white54, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            _buildSummaryRow('Warranty Expiry', receipt.warrantyExpiry ?? 'No Warranty'),
                            _buildSummaryRow('Warranty Duration', receipt.warrantyMonths != null ? '${receipt.warrantyMonths} Months' : 'None'),
                            _buildSummaryRow('Merchant Address', receipt.merchantAddress ?? 'Not Provided', isMuted: true),
                            _buildSummaryRow('Merchant Phone', receipt.merchantPhone ?? 'Not Provided', isMuted: true),
                            _buildSummaryRow('Merchant Email', receipt.merchantEmail ?? 'Not Provided', isMuted: true),
                          ],
                        ),
                      ),
                    ),

                    if (receipt.notes != null && receipt.notes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      BentoCard(
                        glowColor: Colors.transparent,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('NOTES', style: TextStyle(fontSize: 9, letterSpacing: 1.5, color: Colors.white54, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              Text(receipt.notes!, style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.5)),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, bool isMuted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: isMuted ? Colors.white30 : Colors.white60)),
          const SizedBox(width: 24),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isBold ? ReceiptoTheme.secondary : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullscreenImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: InteractiveViewer(
              child: Center(
                child: Image.network(url),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
