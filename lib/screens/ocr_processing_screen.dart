import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/theme.dart';
import '../services/fastapi_ocr_service.dart';
import '../widgets/bento_card.dart';
import '../widgets/kinetic_typography.dart';
import '../widgets/particle_atmosphere.dart';

class OcrProcessingScreen extends StatefulWidget {
  final String filePath;
  const OcrProcessingScreen({Key? key, required this.filePath}) : super(key: key);

  @override
  State<OcrProcessingScreen> createState() => _OcrProcessingScreenState();
}

class _OcrProcessingScreenState extends State<OcrProcessingScreen> {
  final FastApiOcrService _apiService = FastApiOcrService();
  String _statusText = 'Uploading receipt to engine...';
  double _progress = 0.1;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _startOcrProcess();
  }

  Future<void> _startOcrProcess() async {
    try {
      setState(() {
        _statusText = 'Connecting to FastAPI OCR...';
        _progress = 0.3;
        _hasError = false;
      });

      // Simulate step-up progress
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() {
        _statusText = 'Extracting text using PaddleOCR...';
        _progress = 0.6;
      });

      final resultText = await _apiService.uploadAndExtractText(widget.filePath);

      if (!mounted) return;
      setState(() {
        _statusText = 'Structuring output matrices...';
        _progress = 1.0;
      });

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        context.pushReplacement('/ocr', extra: {
          'text': resultText,
          'filePath': widget.filePath,
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _statusText = 'Extraction failed';
        });
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
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: BentoCard(
                    glowColor: _hasError ? ReceiptoTheme.error : ReceiptoTheme.secondary,
                    borderRadius: 32,
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_hasError) ...[
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 64,
                              color: ReceiptoTheme.error,
                            ).animate().shake(),
                            const SizedBox(height: 24),
                            const Text(
                              'CONNECTION ERROR',
                              style: TextStyle(
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
                                    onPressed: _startOcrProcess,
                                    child: Container(
                                      height: 48,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        gradient: const LinearGradient(
                                          colors: [ReceiptoTheme.primary, ReceiptoTheme.secondary],
                                        ),
                                      ),
                                      child: const Text(
                                        'Retry',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            // Rotating Logo Loader
                            const Icon(
                              Icons.sync_rounded,
                              size: 64,
                              color: ReceiptoTheme.secondary,
                            )
                                .animate(onPlay: (controller) => controller.repeat())
                                .rotate(duration: const Duration(seconds: 2)),
                            const SizedBox(height: 28),
                            const Text(
                              'PADDLEOCR SCANNING',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _statusText,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 32),
                            // Linear progress indicator
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: _progress,
                                minHeight: 6,
                                backgroundColor: Colors.white.withOpacity(0.05),
                                valueColor: const AlwaysStoppedAnimation(ReceiptoTheme.secondary),
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
