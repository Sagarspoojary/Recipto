import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme/theme.dart';
import '../models/receipt.dart';
import '../providers/receipt_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/bento_card.dart';
import '../widgets/kinetic_typography.dart';
import '../widgets/particle_atmosphere.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsAsync = ref.watch(receiptsProvider);

    return Scaffold(
      body: ParticleAtmosphere(
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(child: KineticTypography()),
              receiptsAsync.when(
                data: (receipts) => _buildDashboardContent(context, receipts, ref),
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(ReceiptoTheme.secondary),
                  ),
                ),
                error: (e, __) => Center(
                  child: Text('Error loading dashboard: $e', style: const TextStyle(color: ReceiptoTheme.error)),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildFuturisticNavBar(context),
    );
  }

  Widget _buildDashboardContent(BuildContext context, List<Receipt> receipts, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final profile = profileAsync.value;

    final hour = DateTime.now().hour;
    final fullName = profile?.fullName ?? '';
    final cleanName = fullName.isNotEmpty ? fullName.split(' ').first : 'User';
    final greeting = hour < 12 ? 'Good Morning, $cleanName' : 'Welcome Back, $cleanName';

    // Computations for Bento Grid metrics
    final today = DateTime.now();
    final todayReceipts = receipts.where((r) =>
        r.date.year == today.year && r.date.month == today.month && r.date.day == today.day);
    final todayTotal = todayReceipts.fold<double>(0, (sum, r) => sum + r.total);

    final monthlyReceipts = receipts.where((r) => r.date.year == today.year && r.date.month == today.month);
    final monthlyTotal = monthlyReceipts.fold<double>(0, (sum, r) => sum + r.total);

    return CustomScrollView(
      slivers: [
        // App Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RECEIPTO',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: ReceiptoTheme.secondary.withOpacity(0.8),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      greeting,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.logout_rounded, color: Colors.white70),
                      onPressed: () async {
                        await ref.read(authProvider.notifier).signOut();
                        context.go('/login');
                      },
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => context.push('/profile'),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: ReceiptoTheme.secondary.withOpacity(0.5), width: 1.5),
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white.withOpacity(0.05),
                          backgroundImage: profile?.photoURL != null
                              ? NetworkImage(profile!.photoURL!)
                              : null,
                          child: profile?.photoURL == null
                              ? Text(
                                  cleanName.isNotEmpty ? cleanName[0].toUpperCase() : '?',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Bento Grid Body
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Row 1: Today Spending & Monthly Spending (Side by Side)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 140,
                      child: BentoCard(
                        glowColor: ReceiptoTheme.secondary,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('TODAY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.5), letterSpacing: 1)),
                              Text('\$${todayTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                              const Text('OCR Sync Completed', style: TextStyle(fontSize: 9, color: ReceiptoTheme.highlight)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 140,
                      child: BentoCard(
                        glowColor: ReceiptoTheme.primary,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('MONTHLY LIMIT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.5), letterSpacing: 1)),
                              Text('\$${monthlyTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                              const Text('Budget Node: 84% Free', style: TextStyle(fontSize: 9, color: ReceiptoTheme.secondary)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Row 2: AI Insights (Wide Bento)
              SizedBox(
                height: 130,
                child: BentoCard(
                  glowColor: ReceiptoTheme.accent,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.auto_awesome_rounded, color: ReceiptoTheme.accent, size: 16),
                                  SizedBox(width: 8),
                                  Text('AI ENGINE DEEP LEARNING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ReceiptoTheme.accent, letterSpacing: 1.5)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Electronics spending is 12% lower than last month. We recommend archiving tax reports before Q3.',
                                style: TextStyle(fontSize: 12, height: 1.4, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Row 3: Live Chart (Deep 3D Bento)
              SizedBox(
                height: 220,
                child: BentoCard(
                  glowColor: ReceiptoTheme.secondary,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('EXPENSE VECTORS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                        const SizedBox(height: 12),
                        Expanded(
                          child: LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: false),
                              titlesData: const FlTitlesData(show: false),
                              borderData: FlBorderData(show: false),
                              minX: 0,
                              maxX: 6,
                              minY: 0,
                              maxY: 6,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: [
                                    const FlSpot(0, 3),
                                    const FlSpot(1, 2.5),
                                    const FlSpot(2, 5),
                                    const FlSpot(3, 3.1),
                                    const FlSpot(4, 4),
                                    const FlSpot(5, 3.8),
                                    const FlSpot(6, 5.5),
                                  ],
                                  isCurved: true,
                                  gradient: const LinearGradient(
                                    colors: [ReceiptoTheme.primary, ReceiptoTheme.secondary],
                                  ),
                                  barWidth: 4,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      colors: [
                                        ReceiptoTheme.primary.withOpacity(0.2),
                                        ReceiptoTheme.secondary.withOpacity(0.0),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
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
                ),
              ),

              const SizedBox(height: 24),

              // Section Header: Recent Files
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'RECENT DEPOSITS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/analytics'),
                    child: const Text('SEE VECTOR STATS', style: TextStyle(fontSize: 10, color: ReceiptoTheme.secondary)),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Recent Receipts List
              if (receipts.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(child: Text('No vaults scanned yet.', style: TextStyle(color: ReceiptoTheme.textMuted))),
                )
              else
                ...receipts.take(4).map((receipt) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: BentoCard(
                        glowColor: Colors.transparent,
                        borderRadius: 16,
                        onTap: () {
                          // Go to details
                          context.push('/receipt-details', extra: receipt);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.white.withOpacity(0.05),
                                    ),
                                    child: const Icon(Icons.receipt_long_rounded, color: ReceiptoTheme.secondary),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        receipt.merchant,
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${receipt.date.toString().substring(0, 10)} • ${receipt.category}',
                                        style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '\$${receipt.total.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${(receipt.confidence * 100).toInt()}% match',
                                    style: const TextStyle(fontSize: 9, color: ReceiptoTheme.highlight),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    )),
              const SizedBox(height: 100), // Spacing for fab / nav bar
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildFuturisticNavBar(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.dashboard_rounded, color: ReceiptoTheme.secondary),
            onPressed: () {},
          ),
          // Floating Scan Button
          GestureDetector(
            onTap: () => context.push('/scanner'),
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [ReceiptoTheme.primary, ReceiptoTheme.accent],
                ),
                boxShadow: [
                  BoxShadow(
                    color: ReceiptoTheme.primary.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 28),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.06, 1.06), duration: 2.seconds),
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, color: Colors.white54),
            onPressed: () => context.push('/analytics'),
          ),
        ],
      ),
    );
  }
}
