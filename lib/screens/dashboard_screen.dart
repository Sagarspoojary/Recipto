import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/theme.dart';
import '../models/receipt.dart';
import '../providers/receipt_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/bento_card.dart';
import '../widgets/kinetic_typography.dart';
import '../widgets/particle_atmosphere.dart';
import '../widgets/warranty_status_indicator.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

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

  Widget _buildDashboardContent(BuildContext context, List<Receipt> allReceipts, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final profile = profileAsync.value;

    final hour = DateTime.now().hour;
    final fullName = profile?.fullName ?? '';
    final cleanName = fullName.isNotEmpty ? fullName.split(' ').first : 'User';
    final greeting = hour < 12 ? 'Good Morning, $cleanName' : 'Welcome Back, $cleanName';

    // Watch stats & filtered lists from providers
    final stats = ref.watch(dashboardStatsProvider);
    final filteredReceipts = ref.watch(filteredAndSortedReceiptsProvider);

    final totalSpending = stats['totalSpending'] as double? ?? 0.0;
    final totalReceipts = stats['totalReceipts'] as int? ?? 0;
    final activeWarranties = stats['activeWarranties'] as int? ?? 0;
    final expiringSoon = stats['expiringSoon'] as int? ?? 0;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
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
                        if (context.mounted) {
                          context.go('/login');
                        }
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

        // Search Bar & Filters Chips
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                // Search Input Field
                TextField(
                  onChanged: (val) => ref.read(searchQueryProvider.notifier).state = val,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search merchant, product, category...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search_rounded, color: ReceiptoTheme.secondary),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.03),
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
                // Filtering Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip(
                        context,
                        label: 'Category: ${ref.watch(selectedCategoryFilterProvider) ?? 'All'}',
                        onTap: () => _showCategoryFilterDialog(context, ref),
                        isActive: ref.watch(selectedCategoryFilterProvider) != null,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        context,
                        label: 'Date: ${ref.watch(dateRangeFilterProvider) ?? 'All'}',
                        onTap: () => _showDateRangeFilterDialog(context, ref),
                        isActive: ref.watch(dateRangeFilterProvider) != null,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        context,
                        label: 'Warranty: ${ref.watch(warrantyFilterProvider) ?? 'All'}',
                        onTap: () => _showWarrantyFilterDialog(context, ref),
                        isActive: ref.watch(warrantyFilterProvider) != null,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        context,
                        label: 'Sort: ${ref.watch(sortByProvider)}',
                        onTap: () => _showSortDialog(context, ref),
                        isActive: ref.watch(sortByProvider) != 'Newest',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        if (allReceipts.isEmpty) ...[
          // Empty State illustration
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 96,
                      color: Colors.white.withOpacity(0.12),
                    ).animate().scale(delay: 200.ms, duration: 500.ms),
                    const SizedBox(height: 24),
                    const Text(
                      'No receipts yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Tap the Scan button to scan your first receipt.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.white38),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ] else ...[
          // Bento Statistics Row
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  Row(
                    children: [
                      // Spending
                      Expanded(
                        child: SizedBox(
                          height: 145,
                          child: BentoCard(
                            glowColor: ReceiptoTheme.secondary,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('TOTAL SPENDING', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white60, letterSpacing: 1)),
                                  Text('₹${totalSpending.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                                  Text('$totalReceipts Receipts Saved', style: const TextStyle(fontSize: 9, color: ReceiptoTheme.highlight)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Warranties
                      Expanded(
                        child: SizedBox(
                          height: 145,
                          child: BentoCard(
                            glowColor: ReceiptoTheme.primary,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('ACTIVE WARRANTIES', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white60, letterSpacing: 1)),
                                  Text('$activeWarranties Items', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                                  Text(
                                    expiringSoon > 0 ? '$expiringSoon Expiring Soon' : 'All secure',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: expiringSoon > 0 ? Colors.amber : ReceiptoTheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Recent Receipts Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'RECENT RECEIPTS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white60, letterSpacing: 1.5),
                  ),
                  if (filteredReceipts.length != allReceipts.length)
                    Text(
                      'Showing ${filteredReceipts.length} of ${allReceipts.length}',
                      style: const TextStyle(fontSize: 10, color: ReceiptoTheme.highlight),
                    ),
                ],
              ),
            ),
          ),

          // Receipts List View
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final receipt = filteredReceipts[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildReceiptListItem(context, receipt),
                  );
                },
                childCount: filteredReceipts.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ],
    );
  }

  Widget _buildFilterChip(BuildContext context, {required String label, required VoidCallback onTap, required bool isActive}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? ReceiptoTheme.secondary.withOpacity(0.15) : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? ReceiptoTheme.secondary.withOpacity(0.5) : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down_rounded, size: 16, color: isActive ? Colors.white : Colors.white60),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptListItem(BuildContext context, Receipt receipt) {
    final hasWarranty = receipt.warrantyExpiry != null;
    final categoryIcon = _getCategoryIcon(receipt.category);

    return InkWell(
      onTap: () {
        context.push('/receipt/${receipt.receiptId}', extra: receipt);
      },
      borderRadius: BorderRadius.circular(20),
      child: BentoCard(
        glowColor: Colors.white.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Receipt Thumbnail & Warranty Indicators
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 52,
                      height: 52,
                      color: Colors.white.withOpacity(0.03),
                      child: receipt.receiptImageUrl != null && receipt.receiptImageUrl!.isNotEmpty
                          ? Image.network(
                              receipt.receiptImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(categoryIcon, color: ReceiptoTheme.secondary, size: 22),
                            )
                          : Icon(categoryIcon, color: ReceiptoTheme.secondary, size: 22),
                    ),
                  ),
                  const SizedBox(height: 6),
                  WarrantyStatusIndicator(
                    warrantyExpiry: receipt.warrantyExpiry,
                    currentDate: DateTime.now(),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Merchant Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      receipt.merchant,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      receipt.purchaseDate ?? 'No Date',
                      style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.4)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Financials & Warranty info
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${receipt.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  if (hasWarranty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: ReceiptoTheme.highlight.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'WARRANTY',
                        style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: ReceiptoTheme.highlight),
                      ),
                    )
                  else
                    Text(
                      receipt.category,
                      style: const TextStyle(fontSize: 9, color: ReceiptoTheme.secondary),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Electronics':
      case 'Home Appliances':
        return Icons.devices_other_rounded;
      case 'Groceries':
        return Icons.shopping_basket_rounded;
      case 'Restaurant':
        return Icons.restaurant_rounded;
      case 'Medical':
        return Icons.medical_services_rounded;
      case 'Fuel':
        return Icons.local_gas_station_rounded;
      case 'Fashion':
        return Icons.checkroom_rounded;
      case 'Travel':
        return Icons.flight_takeoff_rounded;
      case 'Furniture':
        return Icons.chair_rounded;
      case 'Books':
        return Icons.menu_book_rounded;
      case 'Entertainment':
        return Icons.videogame_asset_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  // Filter sheets definitions
  void _showCategoryFilterDialog(BuildContext context, WidgetRef ref) {
    final current = ref.read(selectedCategoryFilterProvider);
    final categoriesList = [
      'All', 'Electronics', 'Groceries', 'Restaurant', 'Medical', 'Fuel',
      'Fashion', 'Travel', 'Furniture', 'Books', 'Entertainment', 'Home Appliances', 'Others'
    ];

    _showSelectorBottomSheet(
      context,
      title: 'Filter by Category',
      items: categoriesList,
      selectedItem: current ?? 'All',
      onSelect: (item) {
        ref.read(selectedCategoryFilterProvider.notifier).state = item == 'All' ? null : item;
      },
    );
  }

  void _showDateRangeFilterDialog(BuildContext context, WidgetRef ref) {
    final current = ref.read(dateRangeFilterProvider);
    final dateRanges = ['All', 'This Month', 'Last Month', 'This Year'];

    _showSelectorBottomSheet(
      context,
      title: 'Filter by Purchase Date',
      items: dateRanges,
      selectedItem: current ?? 'All',
      onSelect: (item) {
        ref.read(dateRangeFilterProvider.notifier).state = item == 'All' ? null : item;
      },
    );
  }

  void _showWarrantyFilterDialog(BuildContext context, WidgetRef ref) {
    final current = ref.read(warrantyFilterProvider);
    final warrantyStatuses = ['All', 'Expired', 'Expiring Soon'];

    _showSelectorBottomSheet(
      context,
      title: 'Filter by Warranty Status',
      items: warrantyStatuses,
      selectedItem: current ?? 'All',
      onSelect: (item) {
        ref.read(warrantyFilterProvider.notifier).state = item == 'All' ? null : item;
      },
    );
  }

  void _showSortDialog(BuildContext context, WidgetRef ref) {
    final current = ref.read(sortByProvider);
    final sortOptions = ['Newest', 'Oldest', 'Highest Price', 'Lowest Price', 'Merchant Name'];

    _showSelectorBottomSheet(
      context,
      title: 'Sort Receipts',
      items: sortOptions,
      selectedItem: current,
      onSelect: (item) {
        ref.read(sortByProvider.notifier).state = item;
      },
    );
  }

  void _showSelectorBottomSheet(
    BuildContext context, {
    required String title,
    required List<String> items,
    required String selectedItem,
    required Function(String) onSelect,
  }) {
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
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSel = item == selectedItem;
                    return ListTile(
                      title: Text(
                        item,
                        style: TextStyle(color: isSel ? ReceiptoTheme.secondary : Colors.white70, fontWeight: isSel ? FontWeight.bold : FontWeight.normal),
                      ),
                      trailing: isSel ? const Icon(Icons.check_circle_rounded, color: ReceiptoTheme.secondary) : null,
                      onTap: () {
                        onSelect(item);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFuturisticNavBar(BuildContext context) {
    return Container(
      height: 68,
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: ReceiptoTheme.primary.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.dashboard_rounded, color: ReceiptoTheme.secondary, size: 24),
            onPressed: () {},
          ),
          // Floating Scan button
          GestureDetector(
            onTap: () => context.push('/scanner'),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [ReceiptoTheme.primary, ReceiptoTheme.secondary],
                ),
              ),
              child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 20),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white60, size: 24),
            onPressed: () => context.push('/trash'),
          ),
        ],
      ),
    );
  }
}
