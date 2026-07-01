import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/theme.dart';
import '../models/receipt.dart';
import '../providers/receipt_provider.dart';
import '../services/pdf_service.dart';
import '../widgets/bento_card.dart';
import '../widgets/kinetic_typography.dart';
import '../widgets/particle_atmosphere.dart';

class ReceiptDetailsScreen extends ConsumerWidget {
  final Receipt receipt;
  const ReceiptDetailsScreen({Key? key, required this.receipt}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfService = PdfService();

    return Scaffold(
      body: ParticleAtmosphere(
        child: Stack(
          children: [
            const Positioned.fill(child: KineticTypography()),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Toolbar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                receipt.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                                color: receipt.isFavorite ? ReceiptoTheme.warning : Colors.white,
                              ),
                              onPressed: () {
                                ref.read(receiptsProvider.notifier).toggleFavorite(receipt.id);
                                context.pop();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.archive_outlined, color: Colors.white),
                              onPressed: () {
                                ref.read(receiptsProvider.notifier).toggleArchive(receipt.id);
                                context.pop();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: ReceiptoTheme.error),
                              onPressed: () {
                                ref.read(receiptsProvider.notifier).deleteReceipt(receipt.id);
                                context.pop();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Merchant Overview Bento
                    BentoCard(
                      glowColor: ReceiptoTheme.secondary,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.05),
                              ),
                              child: const Icon(Icons.storefront_rounded, color: ReceiptoTheme.secondary, size: 30),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              receipt.merchant.toUpperCase(),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${receipt.date.toString().substring(0, 10)} • ${receipt.category}',
                              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '\$${receipt.total.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Itemized Details Bento
                    BentoCard(
                      glowColor: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ITEMIZED MATRIX', style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.white54)),
                            const SizedBox(height: 16),
                            ...receipt.items.map((item) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.name,
                                          style: const TextStyle(fontSize: 13, color: Colors.white),
                                        ),
                                      ),
                                      Text(
                                        '\$${item.price.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                )),
                            const Divider(height: 24, color: Colors.white12),
                            _buildSummaryRow('Tax', '\$${receipt.tax.toStringAsFixed(2)}'),
                            _buildSummaryRow('Discount', '-\$${receipt.discount.toStringAsFixed(2)}'),
                            const Divider(height: 24, color: Colors.white12),
                            _buildSummaryRow('Total paid', '\$${receipt.total.toStringAsFixed(2)}', isBold: true),
                            const SizedBox(height: 12),
                            _buildSummaryRow('Payment Method', receipt.paymentMethod, isMuted: true),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Actions
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => pdfService.exportAndPrintReceipt(receipt),
                      child: Container(
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [ReceiptoTheme.primary, ReceiptoTheme.secondary],
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'EXPORT SECURE PDF',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.print_rounded, color: Colors.white, size: 16),
                          ],
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

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, bool isMuted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: isMuted ? Colors.white30 : Colors.white60)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? ReceiptoTheme.secondary : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
