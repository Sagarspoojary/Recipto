import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme/theme.dart';
import '../models/receipt.dart';
import '../providers/receipt_provider.dart';
import '../widgets/bento_card.dart';
import '../widgets/kinetic_typography.dart';
import '../widgets/particle_atmosphere.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsAsync = ref.watch(receiptsStreamProvider);

    return Scaffold(
      body: ParticleAtmosphere(
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(child: KineticTypography()),
              receiptsAsync.when(
                data: (receipts) => _buildAnalyticsContent(context, receipts),
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(ReceiptoTheme.secondary),
                  ),
                ),
                error: (e, __) => Center(
                  child: Text('Error: $e', style: const TextStyle(color: ReceiptoTheme.error)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent(BuildContext context, List<Receipt> receipts) {
    // Aggregations
    final double totalSpend = receipts.fold(0, (sum, r) => sum + r.total);

    // Grouping by category
    final Map<String, double> categoryMap = {};
    for (var r in receipts) {
      categoryMap[r.category] = (categoryMap[r.category] ?? 0) + r.total;
    }

    final colors = [
      ReceiptoTheme.primary,
      ReceiptoTheme.secondary,
      ReceiptoTheme.accent,
      ReceiptoTheme.highlight,
      ReceiptoTheme.warning,
      Colors.blue,
      Colors.indigo,
      Colors.amber,
    ];

    int index = 0;
    final List<PieChartSectionData> sections = categoryMap.entries.map((entry) {
      final color = colors[index % colors.length];
      index++;
      final percentage = totalSpend > 0 ? (entry.value / totalSpend * 100).toStringAsFixed(0) : '0';
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '$percentage%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return SingleChildScrollView(
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
                'Expense Analytics',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Total aggregate card
          BentoCard(
            glowColor: ReceiptoTheme.secondary,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ACCUMULATED VECTOR TOTAL', style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.white54)),
                  const SizedBox(height: 8),
                  Text(
                    '\$${totalSpend.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Aggregating across ${receipts.length} vaults',
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Pie Chart representation
          SizedBox(
            height: 250,
            child: BentoCard(
              glowColor: ReceiptoTheme.accent,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: sections.isEmpty
                          ? const Center(child: Text('No data found'))
                          : PieChart(
                              PieChartData(
                                sectionsSpace: 4,
                                centerSpaceRadius: 40,
                                sections: sections,
                              ),
                            ),
                    ),
                    const SizedBox(width: 16),
                    // Legend
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: categoryMap.entries.map((entry) {
                        final colorIndex = categoryMap.keys.toList().indexOf(entry.key);
                        final color = colors[colorIndex % colors.length];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Container(width: 12, height: 12, color: color),
                              const SizedBox(width: 8),
                              Text(
                                entry.key,
                                style: const TextStyle(fontSize: 11, color: Colors.white70),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Weekly vectors bar chart
          SizedBox(
            height: 200,
            child: BentoCard(
              glowColor: ReceiptoTheme.primary,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('WEEKLY VOLUME VECTOR', style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.white54)),
                    const SizedBox(height: 24),
                    Expanded(
                      child: BarChart(
                        BarChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups: [
                            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 8, color: ReceiptoTheme.primary, width: 14)]),
                            BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 10, color: ReceiptoTheme.secondary, width: 14)]),
                            BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 14, color: ReceiptoTheme.accent, width: 14)]),
                            BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 6, color: ReceiptoTheme.highlight, width: 14)]),
                            BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 11, color: ReceiptoTheme.primary, width: 14)]),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
