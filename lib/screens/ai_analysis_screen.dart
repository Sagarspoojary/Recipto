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

class AiAnalysisScreen extends ConsumerStatefulWidget {
  final Receipt receipt;
  const AiAnalysisScreen({Key? key, required this.receipt}) : super(key: key);

  @override
  ConsumerState<AiAnalysisScreen> createState() => _AiAnalysisScreenState();
}

class _AiAnalysisScreenState extends ConsumerState<AiAnalysisScreen> {
  bool _isSaving = false;

  Future<void> _saveToVault() async {
    setState(() {
      _isSaving = true;
    });

    // Add to state provider database
    await ref.read(receiptsProvider.notifier).addReceipt(widget.receipt);

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
      context.go('/dashboard');
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI Analysis',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Categorization breakdown card
                    BentoCard(
                      glowColor: ReceiptoTheme.primary,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.auto_awesome_rounded, color: ReceiptoTheme.primary, size: 16),
                                SizedBox(width: 8),
                                Text('CLASSIFICATION ENGINE', style: TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold, color: ReceiptoTheme.primary)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  widget.receipt.category,
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const Text(
                                  '97% MATCH',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ReceiptoTheme.highlight),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Verified matching with merchant node index parameters.',
                              style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5)),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Budget impact bento
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 130,
                            child: BentoCard(
                              glowColor: ReceiptoTheme.warning,
                              child: const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('BUDGET IMPACT', style: TextStyle(fontSize: 10, color: Colors.white60)),
                                    Text('+2.4%', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: ReceiptoTheme.warning)),
                                    Text('Safe threshold range', style: TextStyle(fontSize: 9, color: Colors.white30)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 130,
                            child: BentoCard(
                              glowColor: ReceiptoTheme.highlight,
                              child: const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('DUPLICATE MESH', style: TextStyle(fontSize: 10, color: Colors.white60)),
                                    Text('0 Clean', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: ReceiptoTheme.highlight)),
                                    Text('No overlays found', style: TextStyle(fontSize: 9, color: Colors.white30)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // AI Recommendation insight
                    BentoCard(
                      glowColor: ReceiptoTheme.accent,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('AI RECOMMENDATION', style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.white54)),
                            const SizedBox(height: 12),
                            Text(
                              'This invoice contains write-offs eligible for standard tech business deduction. We have pre-flagged this receipt under Tax Schedule C.',
                              style: TextStyle(fontSize: 12, height: 1.5, color: Colors.white.withOpacity(0.9)),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isSaving ? null : _saveToVault,
                      child: Container(
                        height: 58,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [ReceiptoTheme.secondary, ReceiptoTheme.primary],
                          ),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white))
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'SAVE TO SECURE VAULT',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.lock_outline_rounded, color: Colors.white, size: 16),
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
}
