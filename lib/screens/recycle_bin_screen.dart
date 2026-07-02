import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/theme/theme.dart';
import '../models/receipt.dart';
import '../providers/receipt_provider.dart';
import '../widgets/bento_card.dart';
import '../widgets/particle_atmosphere.dart';

class RecycleBinScreen extends ConsumerStatefulWidget {
  const RecycleBinScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends ConsumerState<RecycleBinScreen> {
  @override
  void initState() {
    super.initState();
    // Automatically purge receipts that are older than 30 days when entering the Recycle Bin
    Future.microtask(() {
      ref.read(receiptServiceProvider).purgeOldDeletedReceipts();
    });
  }

  int _getDaysRemaining(DateTime? deletedAt) {
    if (deletedAt == null) return 30;
    final now = DateTime.now();
    final difference = now.difference(deletedAt).inDays;
    final remaining = 30 - difference;
    return remaining < 0 ? 0 : remaining;
  }

  void _restoreReceipt(Receipt receipt) async {
    try {
      await ref.read(receiptServiceProvider).restoreReceipt(receipt.receiptId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${receipt.merchant} restored successfully'),
            backgroundColor: ReceiptoTheme.highlight,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore: $e'),
            backgroundColor: ReceiptoTheme.error,
          ),
        );
      }
    }
  }

  void _deletePermanently(Receipt receipt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Permanently?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This action is permanent and cannot be undone. The receipt data and file will be erased.',
          style: TextStyle(color: Colors.white70),
        ),
        backgroundColor: Colors.grey[900],
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ReceiptoTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(receiptServiceProvider).deleteReceiptPermanently(
              receipt.receiptId,
              receipt.receiptImageUrl,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${receipt.merchant} deleted permanently'),
              backgroundColor: ReceiptoTheme.error,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: ReceiptoTheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final trashedReceipts = ref.watch(trashReceiptsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recycle Bin'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: ParticleAtmosphere(
        child: SafeArea(
          child: trashedReceipts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 72, color: Colors.white24),
                      const SizedBox(height: 16),
                      Text(
                        'Recycle Bin is empty',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white30),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Deleted receipts will appear here for 30 days.',
                        style: TextStyle(color: Colors.white24, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20.0),
                  itemCount: trashedReceipts.length,
                  itemBuilder: (context, index) {
                    final receipt = trashedReceipts[index];
                    final daysLeft = _getDaysRemaining(receipt.deletedAt);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: BentoCard(
                        glowColor: daysLeft <= 5 ? ReceiptoTheme.error : ReceiptoTheme.warning,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      receipt.merchant,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '₹${receipt.total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      receipt.category,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.white.withOpacity(0.6),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$daysLeft days remaining',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: daysLeft <= 5 ? ReceiptoTheme.error : Colors.amber,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(color: Colors.white10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _restoreReceipt(receipt),
                                    icon: const Icon(Icons.restore_rounded, size: 18, color: ReceiptoTheme.highlight),
                                    label: const Text('Restore', style: TextStyle(color: ReceiptoTheme.highlight, fontSize: 12)),
                                  ),
                                  const SizedBox(width: 16),
                                  TextButton.icon(
                                    onPressed: () => _deletePermanently(receipt),
                                    icon: const Icon(Icons.delete_forever_rounded, size: 18, color: ReceiptoTheme.error),
                                    label: const Text('Delete', style: TextStyle(color: ReceiptoTheme.error, fontSize: 12)),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
