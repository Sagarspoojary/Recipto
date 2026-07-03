import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/theme/theme.dart';
import '../models/receipt.dart';
import '../providers/analytics_provider.dart';
import '../widgets/bento_card.dart';
import '../widgets/kinetic_typography.dart';
import '../widgets/particle_atmosphere.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(analyticsStatsProvider);
    final currentFilter = ref.watch(analyticsDateFilterProvider);
    final receipts = ref.watch(filteredAnalyticsReceiptsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: ParticleAtmosphere(
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(child: KineticTypography()),
              Column(
                children: [
                  // App Header
                  _buildHeader(context, ref, stats, receipts),
                  // Filter and Search Row
                  _buildFilterAndSearchRow(context, ref, currentFilter),
                  // Main Scrollable Analytics Panels
                  Expanded(
                    child: receipts.isEmpty
                        ? _buildEmptyState()
                        : SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                            child: Column(
                              children: [
                                // Section 1: Expense Analytics
                                _buildExpenseSection(context, stats),
                                const SizedBox(height: 20),
                                // Section 2: Category Analytics
                                _buildCategorySection(context, stats),
                                const SizedBox(height: 20),
                                // Section 3: Merchant Analytics
                                _buildMerchantSection(context, stats),
                                const SizedBox(height: 20),
                                // Section 4: Product Analytics
                                _buildProductSection(context, stats),
                                const SizedBox(height: 20),
                                // Section 5: Receipt Analytics
                                _buildReceiptSection(context, stats),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HEADER WIDGET ---
  Widget _buildHeader(BuildContext context, WidgetRef ref, Map<String, dynamic> stats, List<Receipt> receipts) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analytics',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: ReceiptoTheme.secondary.withOpacity(0.5), blurRadius: 10),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Track expenses, purchases & habits',
                    style: TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                ],
              ),
            ],
          ),
          // Export Button
          IconButton(
            icon: const Icon(Icons.ios_share_rounded, color: ReceiptoTheme.secondary),
            onPressed: () => _showExportMenu(context, stats, receipts),
          ),
        ],
      ),
    );
  }

  // --- FILTERS & SEARCH BAR ---
  Widget _buildFilterAndSearchRow(BuildContext context, WidgetRef ref, AnalyticsDateFilter current) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          // Search Input
          TextField(
            onChanged: (val) => ref.read(analyticsSearchQueryProvider.notifier).state = val,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search merchant, product, category...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search_rounded, color: ReceiptoTheme.secondary, size: 18),
              filled: true,
              fillColor: Colors.white.withOpacity(0.03),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: ReceiptoTheme.secondary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Date Range Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: AnalyticsDateFilter.values.map((filter) {
                final isSelected = filter == current;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    onTap: () async {
                      if (filter == AnalyticsDateFilter.custom) {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: ReceiptoTheme.secondary,
                                  onPrimary: Colors.black,
                                  surface: Colors.black,
                                  onSurface: Colors.white,
                                ),
                                dialogBackgroundColor: Colors.black,
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          ref.read(analyticsCustomDateRangeProvider.notifier).state =
                              CustomDateRange(picked.start, picked.end);
                          ref.read(analyticsDateFilterProvider.notifier).state = filter;
                        }
                      } else {
                        ref.read(analyticsDateFilterProvider.notifier).state = filter;
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? ReceiptoTheme.secondary.withOpacity(0.15) : Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? ReceiptoTheme.secondary.withOpacity(0.5) : Colors.white.withOpacity(0.06),
                        ),
                      ),
                      child: Text(
                        _getFilterLabel(filter),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white60,
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getFilterLabel(AnalyticsDateFilter filter) {
    switch (filter) {
      case AnalyticsDateFilter.today: return 'Today';
      case AnalyticsDateFilter.thisWeek: return 'This Week';
      case AnalyticsDateFilter.thisMonth: return 'This Month';
      case AnalyticsDateFilter.lastMonth: return 'Last Month';
      case AnalyticsDateFilter.last3Months: return 'Last 3 Months';
      case AnalyticsDateFilter.thisYear: return 'This Year';
      case AnalyticsDateFilter.custom: return 'Custom Range';
    }
  }

  // --- SECTION 1: EXPENSE ANALYTICS ---
  Widget _buildExpenseSection(BuildContext context, Map<String, dynamic> stats) {
    final today = stats['todaySpending'] as double? ?? 0.0;
    final weekly = stats['weeklySpending'] as double? ?? 0.0;
    final monthly = stats['monthlySpending'] as double? ?? 0.0;
    final yearly = stats['yearlySpending'] as double? ?? 0.0;
    final avgDaily = stats['avgDailySpending'] as double? ?? 0.0;
    final avgMonthly = stats['avgMonthlySpending'] as double? ?? 0.0;
    final highestMonth = stats['highestSpendingMonth'] as String? ?? 'N/A';
    final lowestMonth = stats['lowestSpendingMonth'] as String? ?? 'N/A';
    final trendList = stats['monthlyTrendData'] as List<MapEntry<String, double>>? ?? [];
    final weeklyBuckets = stats['weeklyTrendData'] as List<double>? ?? [0,0,0,0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('EXPENSE ANALYTICS', Icons.analytics_outlined),
        const SizedBox(height: 12),
        // Grid of Stats
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildMiniStat('Today\'s Spending', '₹${today.toStringAsFixed(0)}', Colors.orangeAccent),
            _buildMiniStat('Weekly Spending', '₹${weekly.toStringAsFixed(0)}', Colors.cyanAccent),
            _buildMiniStat('Monthly Spending', '₹${monthly.toStringAsFixed(0)}', Colors.purpleAccent),
            _buildMiniStat('Yearly Spending', '₹${yearly.toStringAsFixed(0)}', Colors.greenAccent),
            _buildMiniStat('Avg Daily Spent', '₹${avgDaily.toStringAsFixed(0)}', Colors.blueAccent),
            _buildMiniStat('Avg Monthly Spent', '₹${avgMonthly.toStringAsFixed(0)}', Colors.pinkAccent),
            _buildMiniStat('Highest Month', highestMonth, Colors.redAccent),
            _buildMiniStat('Lowest Month', lowestMonth, Colors.tealAccent),
          ],
        ),
        const SizedBox(height: 16),
        // Monthly Spending Line Chart
        SizedBox(
          height: 220,
          width: double.infinity,
          child: BentoCard(
            glowColor: Colors.deepPurple,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Monthly Spending Trend', style: TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: trendList.isEmpty
                        ? const Center(child: Text('Not enough data', style: TextStyle(color: Colors.white30, fontSize: 12)))
                        : LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: false),
                              titlesData: const FlTitlesData(show: false),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: List.generate(trendList.length, (idx) => FlSpot(idx.toDouble(), trendList[idx].value)),
                                  isCurved: true,
                                  color: ReceiptoTheme.secondary,
                                  barWidth: 3,
                                  belowBarData: BarAreaData(show: true, color: ReceiptoTheme.secondary.withOpacity(0.15)),
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
        const SizedBox(height: 16),
        // Weekly Spending Bar Chart
        SizedBox(
          height: 180,
          width: double.infinity,
          child: BentoCard(
            glowColor: Colors.tealAccent,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Weekly Spending Volume', style: TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: BarChart(
                      BarChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(4, (index) {
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: weeklyBuckets[index],
                                color: index == 3 ? ReceiptoTheme.secondary : ReceiptoTheme.primary,
                                width: 14,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- SECTION 2: CATEGORY ANALYTICS ---
  Widget _buildCategorySection(BuildContext context, Map<String, dynamic> stats) {
    final catStats = stats['categoryStats'] as List<dynamic>? ?? [];

    // Construct Pie Chart Sections
    final colors = [
      ReceiptoTheme.primary,
      ReceiptoTheme.secondary,
      ReceiptoTheme.accent,
      ReceiptoTheme.highlight,
      Colors.indigoAccent,
      Colors.deepOrangeAccent,
      Colors.greenAccent,
      Colors.pinkAccent,
      Colors.amberAccent,
      Colors.tealAccent,
    ];

    final List<PieChartSectionData> pieSections = [];
    for (int i = 0; i < catStats.length; i++) {
      final stat = catStats[i];
      final amount = stat['amount'] as double? ?? 0.0;
      final percentage = stat['percentage'] as double? ?? 0.0;
      if (percentage > 2) {
        pieSections.add(PieChartSectionData(
          color: colors[i % colors.length],
          value: amount,
          title: '${percentage.toStringAsFixed(0)}%',
          radius: 40,
          titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('CATEGORY ANALYTICS', Icons.pie_chart_outline_rounded),
        const SizedBox(height: 12),
        // Pie Chart Bento Card
        if (pieSections.isNotEmpty)
          SizedBox(
            height: 200,
            child: BentoCard(
              glowColor: Colors.pink,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 35,
                          sections: pieSections,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Legends
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(catStats.length, (idx) {
                            final stat = catStats[idx];
                            final cat = stat['category'] as String;
                            final pct = stat['percentage'] as double? ?? 0.0;
                            final col = colors[idx % colors.length];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3.0),
                              child: Row(
                                children: [
                                  Container(width: 8, height: 8, color: col),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '$cat (${pct.toStringAsFixed(0)}%)',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 10, color: Colors.white70),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        // Grid lists of category details
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: catStats.length,
          itemBuilder: (context, idx) {
            final stat = catStats[idx];
            final cat = stat['category'] as String;
            final amount = stat['amount'] as double? ?? 0.0;
            final count = stat['count'] as int? ?? 0;
            final pct = stat['percentage'] as double? ?? 0.0;
            final avg = stat['average'] as double? ?? 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: BentoCard(
                glowColor: Colors.white.withOpacity(0.04),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cat, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('$count Receipts  •  Avg ₹${avg.toStringAsFixed(0)}', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5))),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('${pct.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 10, color: ReceiptoTheme.highlight, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // --- SECTION 3: MERCHANT ANALYTICS ---
  Widget _buildMerchantSection(BuildContext context, Map<String, dynamic> stats) {
    final topMerchants = stats['top10Merchants'] as List<dynamic>? ?? [];
    final mostVisited = stats['mostVisitedMerchant'] as String? ?? 'N/A';
    final highestSpending = stats['highestSpendingMerchant'] as String? ?? 'N/A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('MERCHANT ANALYTICS', Icons.storefront_rounded),
        const SizedBox(height: 12),
        // Mini stats row
        Row(
          children: [
            Expanded(child: _buildMiniStat('Most Visited', mostVisited, Colors.tealAccent)),
            const SizedBox(width: 12),
            Expanded(child: _buildMiniStat('Highest Spent', highestSpending, Colors.redAccent)),
          ],
        ),
        const SizedBox(height: 16),
        // Horizontal Bar Chart or List of top merchants
        const Text(
          'Top Merchants Breakdown',
          style: TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        const SizedBox(height: 12),
        ...List.generate(topMerchants.length, (idx) {
          final stat = topMerchants[idx];
          final name = stat['merchant'] as String;
          final amount = stat['amount'] as double? ?? 0.0;
          final count = stat['count'] as int? ?? 0;
          final avg = stat['average'] as double? ?? 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: BentoCard(
              glowColor: Colors.white.withOpacity(0.02),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$count purchases', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5))),
                        Text('Avg: ₹${avg.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10, color: ReceiptoTheme.secondary)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // --- SECTION 4: PRODUCT ANALYTICS ---
  Widget _buildProductSection(BuildContext context, Map<String, dynamic> stats) {
    final totalProducts = stats['totalProductsPurchased'] as int? ?? 0;
    final mostPurchased = stats['mostPurchasedProduct'] as String? ?? 'N/A';
    final mostExpensive = stats['mostExpensiveProduct'] as String? ?? 'N/A';
    final leastExpensive = stats['leastExpensiveProduct'] as String? ?? 'N/A';
    final avgProductPrice = stats['averageProductPrice'] as double? ?? 0.0;
    final mostPurchasedBrand = stats['mostPurchasedBrand'] as String? ?? 'N/A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('PRODUCT ANALYTICS', Icons.shopping_bag_outlined),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildMiniStat('Total Items', '$totalProducts Items', Colors.indigoAccent),
            _buildMiniStat('Avg Product Price', '₹${avgProductPrice.toStringAsFixed(0)}', Colors.cyanAccent),
            _buildMiniStat('Most Purchased', mostPurchased, Colors.greenAccent),
            _buildMiniStat('Most Expensive', mostExpensive, Colors.redAccent),
            _buildMiniStat('Least Expensive', leastExpensive, Colors.tealAccent),
            _buildMiniStat('Popular Brand', mostPurchasedBrand, Colors.amberAccent),
          ],
        ),
      ],
    );
  }

  // --- SECTION 5: RECEIPT ANALYTICS ---
  Widget _buildReceiptSection(BuildContext context, Map<String, dynamic> stats) {
    final totalReceipts = stats['totalReceipts'] as int? ?? 0;
    final cameraScans = stats['cameraScans'] as int? ?? 0;
    final galleryUploads = stats['galleryUploads'] as int? ?? 0;
    final pdfUploads = stats['pdfUploads'] as int? ?? 0;
    final largest = stats['largestReceipt'] as double? ?? 0.0;
    final smallest = stats['smallestReceipt'] as double? ?? 0.0;
    final average = stats['averageReceiptValue'] as double? ?? 0.0;
    final confidence = stats['averageOCRConfidence'] as double? ?? 0.0;
    final storageKB = stats['totalStorageUsedKB'] as double? ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('RECEIPT ANALYTICS', Icons.receipt_long_rounded),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildMiniStat('Total Vaults', '$totalReceipts Saved', Colors.deepPurpleAccent),
            _buildMiniStat('Avg OCR Confidence', '${confidence.toStringAsFixed(1)}%', Colors.greenAccent),
            _buildMiniStat('Largest Receipt', '₹${largest.toStringAsFixed(0)}', Colors.orangeAccent),
            _buildMiniStat('Smallest Receipt', '₹${smallest.toStringAsFixed(0)}', Colors.cyanAccent),
            _buildMiniStat('Average Receipt', '₹${average.toStringAsFixed(0)}', Colors.pinkAccent),
            _buildMiniStat('Index Storage', '${(storageKB / 1024).toStringAsFixed(2)} MB', Colors.blueAccent),
          ],
        ),
        const SizedBox(height: 16),
        // Upload distribution bento card
        SizedBox(
          height: 150,
          child: BentoCard(
            glowColor: Colors.blueAccent,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Upload Distribution', style: TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildUploadStatItem('Camera', cameraScans, Icons.camera_alt_outlined, Colors.greenAccent),
                      _buildUploadStatItem('Gallery', galleryUploads, Icons.photo_library_outlined, Colors.cyanAccent),
                      _buildUploadStatItem('PDF', pdfUploads, Icons.picture_as_pdf_outlined, Colors.redAccent),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- SECTION SUB-WIDGETS ---
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: ReceiptoTheme.secondary, size: 16),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, Color glowColor) {
    return BentoCard(
      glowColor: glowColor.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: Colors.white38, letterSpacing: 0.5),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadStatItem(String label, int value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text('$value', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.4))),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 72, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 16),
            const Text(
              'No receipts match filter range',
              style: TextStyle(fontSize: 14, color: Colors.white60, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // --- EXPORT FUNCTIONALITIES ---
  void _showExportMenu(BuildContext context, Map<String, dynamic> stats, List<Receipt> receipts) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.95),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Export Options', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.description_outlined, color: Colors.greenAccent),
                title: const Text('Export as CSV', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _exportAsCSV(receipts);
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_view_outlined, color: Colors.blueAccent),
                title: const Text('Export as Excel (XML/CSV)', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _exportAsCSV(receipts, isExcel: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined, color: Colors.redAccent),
                title: const Text('Export / Print PDF Report', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _exportAsPDF(stats, receipts);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _exportAsCSV(List<Receipt> receipts, {bool isExcel = false}) async {
    final buffer = StringBuffer();
    // Headers
    buffer.writeln('ID,Merchant,Category,Date,Total,Currency,Notes');
    for (final r in receipts) {
      final cleanNotes = (r.notes ?? '').replaceAll(',', ' ');
      buffer.writeln('${r.receiptId},"${r.merchant}","${r.category}",${r.purchaseDate ?? ''},${r.total},${r.currency},"$cleanNotes"');
    }

    final directory = Directory.systemTemp;
    final file = File('${directory.path}/receipts_analytics_${isExcel ? 'excel' : 'report'}.csv');
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles([XFile(file.path)], text: 'Receipto Analytics Export');
  }

  void _exportAsPDF(Map<String, dynamic> stats, List<Receipt> receipts) async {
    final pdf = pw.Document();

    final total = stats['totalReceipts'] as int? ?? 0;
    final monthlySpending = stats['monthlySpending'] as double? ?? 0.0;
    final totalSpending = stats['totalSpending'] as double? ?? 0.0;
    final avgReceipt = stats['averageReceiptValue'] as double? ?? 0.0;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('RECEIPTO ANALYTICS REPORT', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text('Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}'),
                pw.SizedBox(height: 24),
                pw.Text('Summary Stats', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Divider(),
                pw.SizedBox(height: 12),
                pw.Text('Total Receipts Scanned: $total'),
                pw.Text('This Month\'s Spending: INR ${monthlySpending.toStringAsFixed(2)}'),
                pw.Text('Total Logged Spending: INR ${totalSpending.toStringAsFixed(2)}'),
                pw.Text('Average Spent per Receipt: INR ${avgReceipt.toStringAsFixed(2)}'),
                pw.SizedBox(height: 32),
                pw.Text('Vault Receipts List', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Divider(),
                pw.SizedBox(height: 12),
                pw.TableHelper.fromTextArray(
                  headers: ['Merchant', 'Category', 'Date', 'Total'],
                  data: receipts.map((r) => [
                    r.merchant,
                    r.category,
                    r.purchaseDate ?? '',
                    r.total.toStringAsFixed(2),
                  ]).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
