import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/theme.dart';
import '../widgets/bento_card.dart';
import '../widgets/kinetic_typography.dart';
import '../widgets/particle_atmosphere.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({Key? key}) : super(key: key);

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _cameraGranted = false;
  bool _storageGranted = false;
  bool _notificationsGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final camera = await Permission.camera.isGranted;
    final storage = await Permission.storage.isGranted;
    final notifications = await Permission.notification.isGranted;

    setState(() {
      _cameraGranted = camera;
      _storageGranted = storage;
      _notificationsGranted = notifications;
    });
  }

  Future<void> _requestPermission(Permission permission, Function(bool) onResult) async {
    final status = await permission.request();
    onResult(status.isGranted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ParticleAtmosphere(
        child: Stack(
          children: [
            const Positioned.fill(child: KineticTypography()),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'AI Permissions',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        shadows: [
                          Shadow(
                            color: ReceiptoTheme.secondary.withOpacity(0.5),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),

                    const SizedBox(height: 8),

                    Text(
                      'Configure your access nodes to optimize OCR scanner efficiency.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: ReceiptoTheme.textSecondary,
                          ),
                    ).animate().fadeIn(duration: 500.ms, delay: 100.ms),

                    const SizedBox(height: 40),

                    // Camera permission card
                    _PermissionCard(
                      title: 'Optic Scanner Access',
                      description: 'Allows camera usage for instant, offline receipt boundary OCR capture.',
                      icon: Icons.camera_enhance_rounded,
                      isGranted: _cameraGranted,
                      color: ReceiptoTheme.secondary,
                      onToggle: () => _requestPermission(Permission.camera, (granted) {
                        setState(() => _cameraGranted = granted);
                      }),
                    ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

                    const SizedBox(height: 16),

                    // Storage permission card
                    _PermissionCard(
                      title: 'Internal Memory Write',
                      description: 'Required to pick image invoices and generate offline high-res PDF exports.',
                      icon: Icons.folder_copy_rounded,
                      isGranted: _storageGranted,
                      color: ReceiptoTheme.primary,
                      onToggle: () => _requestPermission(Permission.storage, (granted) {
                        setState(() => _storageGranted = granted);
                      }),
                    ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

                    const SizedBox(height: 16),

                    // Notifications permission card
                    _PermissionCard(
                      title: 'Neural Push Uplink',
                      description: 'Alerts you about budget triggers and monthly tax report compilations.',
                      icon: Icons.notifications_active_rounded,
                      isGranted: _notificationsGranted,
                      color: ReceiptoTheme.accent,
                      onToggle: () => _requestPermission(Permission.notification, (granted) {
                        setState(() => _notificationsGranted = granted);
                      }),
                    ).animate().fadeIn(duration: 400.ms, delay: 400.ms),

                    const SizedBox(height: 48),

                    // Continue button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: () => context.go('/dashboard'),
                      child: Container(
                        height: 60,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            colors: [ReceiptoTheme.primary, ReceiptoTheme.secondary],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: ReceiptoTheme.secondary.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'INITIALIZE CORE SYSTEM',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.power_settings_new_rounded, color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(duration: 500.ms, delay: 500.ms),
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

class _PermissionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isGranted;
  final Color color;
  final VoidCallback onToggle;

  const _PermissionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isGranted,
    required this.color,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      glowColor: color,
      borderRadius: 24,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isGranted ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                border: Border.all(
                  color: isGranted ? color : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Icon(
                icon,
                color: isGranted ? color : Colors.white.withOpacity(0.4),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch(
              value: isGranted,
              onChanged: (_) => onToggle(),
              activeColor: color,
              activeTrackColor: color.withOpacity(0.3),
              inactiveThumbColor: Colors.white.withOpacity(0.6),
              inactiveTrackColor: Colors.white.withOpacity(0.1),
            ),
          ],
        ),
      ),
    );
  }
}
