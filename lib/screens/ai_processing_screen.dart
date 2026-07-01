import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/theme.dart';
import '../services/fastapi_ocr_service.dart';
import '../widgets/bento_card.dart';
import '../widgets/kinetic_typography.dart';
import '../widgets/particle_atmosphere.dart';

class AiProcessingScreen extends StatefulWidget {
  final String ocrText;
  const AiProcessingScreen({Key? key, required this.ocrText}) : super(key: key);

  @override
  State<AiProcessingScreen> createState() => _AiProcessingScreenState();
}

class _AiProcessingScreenState extends State<AiProcessingScreen> {
  final FastApiOcrService _apiService = FastApiOcrService();
  final List<String> _statusPhrases = [
    'Analyzing Receipt...',
    'Understanding Products...',
    'Detecting Warranty...',
    'Calculating Totals...',
    'Generating Structured Data...',
  ];
  int _phraseIndex = 0;
  Timer? _phraseTimer;
  double _progress = 0.1;
  bool _hasError = false;
  bool _isOffline = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _startPhraseRotation();
    _startAiExtraction();
  }

  void _startPhraseRotation() {
    _phraseTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _phraseIndex = (_phraseIndex + 1) % _statusPhrases.length;
          _progress = 0.1 + (_phraseIndex / _statusPhrases.length) * 0.8;
        });
      }
    });
  }

  Future<void> _startAiExtraction() async {
    try {
      setState(() {
        _hasError = false;
        _isOffline = false;
        _progress = 0.1;
        _phraseIndex = 0;
      });

      final jsonResult = await _apiService.runAiExtraction(widget.ocrText);
      
      _phraseTimer?.cancel();
      if (mounted) {
        setState(() {
          _progress = 1.0;
        });
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          context.pushReplacement('/scanner/ai-review', extra: jsonResult);
        }
      }
    } catch (e) {
      _phraseTimer?.cancel();
      final errStr = e.toString();
      if (mounted) {
        setState(() {
          _hasError = true;
          _progress = 0.0;
          if (errStr.contains('AI Engine Offline') || errStr.contains('503')) {
            _isOffline = true;
            _errorMessage = 'AI Engine Offline. Make sure Ollama is running locally with qwen2.5:7b.';
          } else {
            _errorMessage = 'Unable to understand receipt. Run AI Again.';
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _phraseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ParticleAtmosphere(
        child: Stack(
          children: [
            const Positioned.fill(child: KineticTypography()),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: BentoCard(
                    glowColor: _hasError ? ReceiptoTheme.error : ReceiptoTheme.primary,
                    borderRadius: 32,
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_hasError) ...[
                            Icon(
                              _isOffline ? Icons.wifi_off_rounded : Icons.psychology_alt_outlined,
                              size: 64,
                              color: ReceiptoTheme.error,
                            ).animate().shake(),
                            const SizedBox(height: 24),
                            Text(
                              _isOffline ? 'AI ENGINE OFFLINE' : 'EXTRACTION ERROR',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white60,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: Colors.white.withOpacity(0.12)),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    onPressed: () => context.pop(),
                                    child: const Text('Back', style: TextStyle(color: Colors.white70)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    onPressed: () {
                                      _startPhraseRotation();
                                      _startAiExtraction();
                                    },
                                    child: Container(
                                      height: 48,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        gradient: const LinearGradient(
                                          colors: [ReceiptoTheme.primary, ReceiptoTheme.secondary],
                                        ),
                                      ),
                                      child: Text(
                                        _isOffline ? 'Retry' : 'Run AI Again',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            // Processing spinner
                            const Icon(
                              Icons.psychology_outlined,
                              size: 64,
                              color: ReceiptoTheme.primary,
                            )
                                .animate(onPlay: (controller) => controller.repeat())
                                .scaleXY(begin: 0.9, end: 1.1, duration: const Duration(seconds: 1), curve: Curves.easeInOut)
                                .then()
                                .scaleXY(begin: 1.1, end: 0.9, duration: const Duration(seconds: 1), curve: Curves.easeInOut),
                            const SizedBox(height: 28),
                            const Text(
                              'AI UNDERSTANDING ACTIVE',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Transitioning phrases
                            SizedBox(
                              height: 20,
                              child: Text(
                                _statusPhrases[_phraseIndex],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: ReceiptoTheme.secondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ).animate(key: ValueKey(_phraseIndex)).fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0),
                            ),
                            const SizedBox(height: 32),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: _progress,
                                minHeight: 6,
                                backgroundColor: Colors.white.withOpacity(0.05),
                                valueColor: const AlwaysStoppedAnimation(ReceiptoTheme.primary),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
