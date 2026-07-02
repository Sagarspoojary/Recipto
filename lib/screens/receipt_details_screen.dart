import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
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
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
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

  Future<void> _exportAsPdf(BuildContext context, Receipt receipt) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: ReceiptoTheme.secondary),
      ),
    );

    try {
      final pdf = pw.Document();
      
      pw.MemoryImage? pdfImage;
      if (receipt.receiptImageUrl != null && receipt.receiptImageUrl!.isNotEmpty) {
        try {
          final response = await http.get(Uri.parse(receipt.receiptImageUrl!));
          if (response.statusCode == 200) {
            pdfImage = pw.MemoryImage(response.bodyBytes);
          }
        } catch (e) {
          print('Failed to load image for PDF embedding: $e');
        }
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('RECEIPTO - WARRANTY SLIP', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: PdfColors.blueGrey800)),
                  pw.Text(receipt.purchaseDate ?? '', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Text(receipt.merchant, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24, color: PdfColors.black)),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Invoice: ${receipt.invoiceNumber ?? 'N/A'}', style: const pw.TextStyle(fontSize: 11)),
                pw.Text('Date: ${receipt.purchaseDate ?? 'N/A'}', style: const pw.TextStyle(fontSize: 11)),
              ],
            ),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 12),
            pw.Text('WARRANTY DETAILS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.blueGrey700)),
            pw.SizedBox(height: 6),
            pw.Row(
              children: [
                pw.Text('Warranty Expiry: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(receipt.warrantyExpiry ?? 'No active warranty'),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Text('ITEMIZED PRODUCTS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.blueGrey700)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.symmetric(inside: const pw.BorderSide(color: PdfColors.grey200, width: 0.5)),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Item Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Brand', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Unit Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                  ],
                ),
                ...receipt.products.map((item) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item.name, style: const pw.TextStyle(fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item.brand ?? '', style: const pw.TextStyle(fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item.quantity.toString(), style: const pw.TextStyle(fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('INR ${item.unitPrice.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('INR ${item.totalPrice.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10))),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Subtotal: INR ${receipt.subtotal.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 11)),
                    pw.Text('GST: INR ${receipt.gst.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 11)),
                    pw.Text('Discount: INR ${receipt.discount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 11)),
                    pw.Divider(color: PdfColors.grey400, thickness: 1),
                    pw.Text('Total Paid: INR ${receipt.total.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      if (pdfImage != null) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text('ATTACHED RECEIPT IMAGE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.blueGrey800)),
                    pw.SizedBox(height: 16),
                    pw.Container(
                      height: 500,
                      child: pw.Image(pdfImage!),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }

      Navigator.pop(context);

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'receipt_${receipt.merchant.replaceAll(' ', '_')}_${receipt.receiptId}.pdf',
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate PDF: $e'), backgroundColor: ReceiptoTheme.error),
      );
    }
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
                              icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                              onPressed: () => _exportAsPdf(context, receipt),
                            ),
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
                    _buildVerificationDetailsCard(context, receipt),
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

  Widget _buildVerificationDetailsCard(BuildContext context, Receipt receipt) {
    final verification = receipt.verification;
    final trustScore = verification?.trustScore ?? 100;
    final status = verification?.status ?? 'Verified';
    final verifiedAt = verification?.verifiedAt ?? DateTime.now().toIso8601String();
    final checks = verification?.checks ?? {
      'duplicateInvoice': false,
      'gstValid': true,
      'totalValid': true,
      'dateValid': true,
      'merchantValid': true,
      'ocrConfidenceHigh': true,
      'warrantyValid': true,
      'negativePriceValid': true,
      'currencyValid': true,
      'completenessValid': true,
    };

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'Verified':
        statusColor = const Color(0xFF00FF66);
        statusIcon = Icons.shield_rounded;
        break;
      case 'Review':
        statusColor = const Color(0xFFFFB300);
        statusIcon = Icons.warning_rounded;
        break;
      default:
        statusColor = const Color(0xFFFF3333);
        statusIcon = Icons.error_rounded;
    }

    final checkLabels = {
      'duplicateInvoice': 'Invoice Unique',
      'totalValid': 'Grand Total Correct',
      'gstValid': 'GST Subtotal Correct',
      'dateValid': 'Purchase Date Valid',
      'ocrConfidenceHigh': 'OCR Confidence High',
      'warrantyValid': 'Warranty Duration Valid',
      'merchantValid': 'Merchant Info Complete',
      'negativePriceValid': 'Prices Non-negative',
      'currencyValid': 'Supported Currency (INR/USD/EUR)',
      'completenessValid': 'Essential Fields Present',
    };

    final passedList = <String>[];
    final failedList = <String>[];

    checks.forEach((key, val) {
      final label = checkLabels[key] ?? key;
      final value = val as bool;
      if (key == 'duplicateInvoice') {
        if (value == false) {
          passedList.add(label);
        } else {
          failedList.add('Duplicate Invoice Found');
        }
      } else {
        if (value == true) {
          passedList.add(label);
        } else {
          if (key == 'totalValid') failedList.add('Grand Total Mismatch');
          else if (key == 'gstValid') failedList.add('GST/Subtotal Mismatch');
          else if (key == 'dateValid') failedList.add('Future/Invalid Date');
          else if (key == 'ocrConfidenceHigh') failedList.add('Low OCR Confidence');
          else if (key == 'warrantyValid') failedList.add('Invalid Warranty Dates');
          else if (key == 'merchantValid') failedList.add('Missing Merchant Fields');
          else if (key == 'negativePriceValid') failedList.add('Negative Price Found');
          else if (key == 'currencyValid') failedList.add('Unsupported Currency');
          else if (key == 'completenessValid') failedList.add('Missing Essential Fields');
          else failedList.add(label);
        }
      }
    });

    return BentoCard(
      glowColor: statusColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'RECEIPT VERIFICATION',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white60, letterSpacing: 1.5),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.4), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        status,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.02),
                    border: Border.all(color: statusColor.withOpacity(0.3), width: 3),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$trustScore%',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: statusColor),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Verification Report',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Verified at: ${verifiedAt.split('T')[0]}',
                        style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.4)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (failedList.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('FAILED CHECKS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFFF3333), letterSpacing: 1)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: failedList.map((f) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3333).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cancel_rounded, color: Color(0xFFFF3333), size: 12),
                      const SizedBox(width: 4),
                      Text(f, style: const TextStyle(fontSize: 9, color: Colors.white70)),
                    ],
                  ),
                )).toList(),
              ),
            ],
            if (passedList.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('PASSED CHECKS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF00FF66), letterSpacing: 1)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: passedList.map((p) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF66).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF00FF66), size: 12),
                      const SizedBox(width: 4),
                      Text(p, style: const TextStyle(fontSize: 9, color: Colors.white70)),
                    ],
                  ),
                )).toList(),
              ),
            ],
          ],
        ),
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
