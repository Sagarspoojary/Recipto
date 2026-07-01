import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/receipt.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

final receiptServiceProvider = Provider<ReceiptService>((ref) {
  final authState = ref.watch(authProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        throw Exception('User not logged in');
      }
      return FirestoreReceiptService(userId: user.uid);
    },
    loading: () => throw Exception('Auth loading'),
    error: (e, __) => throw Exception('Auth error: $e'),
  );
});

// Stream provider for realtime Firestore listeners
final receiptsStreamProvider = StreamProvider<List<Receipt>>((ref) {
  final service = ref.watch(receiptServiceProvider);
  return service.getReceiptsStream();
});

// Search & Filtering State Providers
final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedCategoryFilterProvider = StateProvider<String?>((ref) => null);
final dateRangeFilterProvider = StateProvider<String?>((ref) => null); // null, "This Month", "Last Month", "This Year"
final warrantyFilterProvider = StateProvider<String?>((ref) => null); // null, "Expired", "Expiring Soon"
final sortByProvider = StateProvider<String>((ref) => 'Newest'); // "Newest", "Oldest", "Highest Price", "Lowest Price", "Merchant Name"

// Combined filtered & sorted receipts list
final filteredAndSortedReceiptsProvider = Provider<List<Receipt>>((ref) {
  final receiptsAsync = ref.watch(receiptsStreamProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final selectedCategory = ref.watch(selectedCategoryFilterProvider);
  final dateRange = ref.watch(dateRangeFilterProvider);
  final warrantyStatus = ref.watch(warrantyFilterProvider);
  final sortBy = ref.watch(sortByProvider);

  return receiptsAsync.maybeWhen(
    data: (list) {
      final now = DateTime.now();

      // Apply Search & Filters
      final filtered = list.where((receipt) {
        // 1. Search Query Match
        final matchesSearch = query.isEmpty ||
            receipt.merchant.toLowerCase().contains(query) ||
            (receipt.invoiceNumber != null && receipt.invoiceNumber!.toLowerCase().contains(query)) ||
            (receipt.notes != null && receipt.notes!.toLowerCase().contains(query)) ||
            receipt.category.toLowerCase().contains(query) ||
            receipt.products.any((p) =>
                p.name.toLowerCase().contains(query) ||
                (p.brand != null && p.brand!.toLowerCase().contains(query)));

        // 2. Category Match
        final matchesCategory = selectedCategory == null || receipt.category == selectedCategory;

        // 3. Date Range Match
        bool matchesDate = true;
        if (receipt.purchaseDate != null) {
          final pDate = DateTime.tryParse(receipt.purchaseDate!);
          if (pDate != null) {
            if (dateRange == 'This Month') {
              matchesDate = pDate.year == now.year && pDate.month == now.month;
            } else if (dateRange == 'Last Month') {
              final lastMonth = now.month == 1 ? 12 : now.month - 1;
              final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;
              matchesDate = pDate.year == lastMonthYear && pDate.month == lastMonth;
            } else if (dateRange == 'This Year') {
              matchesDate = pDate.year == now.year;
            }
          }
        }

        // 4. Warranty Match
        bool matchesWarranty = true;
        if (warrantyStatus != null && receipt.warrantyExpiry != null) {
          final expiry = DateTime.tryParse(receipt.warrantyExpiry!);
          if (expiry != null) {
            if (warrantyStatus == 'Expired') {
              matchesWarranty = expiry.isBefore(now);
            } else if (warrantyStatus == 'Expiring Soon') {
              final daysLeft = expiry.difference(now).inDays;
              matchesWarranty = expiry.isAfter(now) && daysLeft <= 30;
            }
          } else {
            matchesWarranty = false;
          }
        } else if (warrantyStatus != null && receipt.warrantyExpiry == null) {
          matchesWarranty = false;
        }

        return matchesSearch && matchesCategory && matchesDate && matchesWarranty;
      }).toList();

      // Apply Sorting
      filtered.sort((a, b) {
        switch (sortBy) {
          case 'Oldest':
            final dateA = DateTime.tryParse(a.purchaseDate ?? '') ?? a.createdAt ?? DateTime(1970);
            final dateB = DateTime.tryParse(b.purchaseDate ?? '') ?? b.createdAt ?? DateTime(1970);
            return dateA.compareTo(dateB);
          case 'Highest Price':
            return b.total.compareTo(a.total);
          case 'Lowest Price':
            return a.total.compareTo(b.total);
          case 'Merchant Name':
            return a.merchant.toLowerCase().compareTo(b.merchant.toLowerCase());
          case 'Newest':
          default:
            final dateA = DateTime.tryParse(a.purchaseDate ?? '') ?? a.createdAt ?? DateTime(1970);
            final dateB = DateTime.tryParse(b.purchaseDate ?? '') ?? b.createdAt ?? DateTime(1970);
            return dateB.compareTo(dateA);
        }
      });

      return filtered;
    },
    orElse: () => [],
  );
});

// Analytics Dashboard statistics provider
final dashboardStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final receiptsAsync = ref.watch(receiptsStreamProvider);

  return receiptsAsync.maybeWhen(
    data: (list) {
      if (list.isEmpty) {
        return {
          'totalReceipts': 0,
          'totalSpending': 0.0,
          'avgSpending': 0.0,
          'highestPurchase': 0.0,
          'activeWarranties': 0,
          'expiringSoon': 0,
          'categoryCount': <String, int>{},
          'mostPurchasedCategory': 'None',
        };
      }

      double totalSpending = 0.0;
      double highestPurchase = 0.0;
      int activeWarranties = 0;
      int expiringSoon = 0;
      final categoryCount = <String, int>{};
      final now = DateTime.now();

      for (final r in list) {
        totalSpending += r.total;
        if (r.total > highestPurchase) {
          highestPurchase = r.total;
        }

        // Category counting
        categoryCount[r.category] = (categoryCount[r.category] ?? 0) + 1;

        // Warranty calculations
        if (r.warrantyExpiry != null) {
          final expiry = DateTime.tryParse(r.warrantyExpiry!);
          if (expiry != null) {
            if (expiry.isAfter(now)) {
              activeWarranties++;
              final daysLeft = expiry.difference(now).inDays;
              if (daysLeft <= 30) {
                expiringSoon++;
              }
            }
          }
        }
      }

      // Find most purchased category
      String mostPurchasedCat = 'None';
      int maxCount = 0;
      categoryCount.forEach((cat, count) {
        if (count > maxCount) {
          maxCount = count;
          mostPurchasedCat = cat;
        }
      });

      return {
        'totalReceipts': list.length,
        'totalSpending': totalSpending,
        'avgSpending': totalSpending / list.length,
        'highestPurchase': highestPurchase,
        'activeWarranties': activeWarranties,
        'expiringSoon': expiringSoon,
        'categoryCount': categoryCount,
        'mostPurchasedCategory': mostPurchasedCat,
      };
    },
    orElse: () => {
      'totalReceipts': 0,
      'totalSpending': 0.0,
      'avgSpending': 0.0,
      'highestPurchase': 0.0,
      'activeWarranties': 0,
      'expiringSoon': 0,
      'categoryCount': <String, int>{},
      'mostPurchasedCategory': 'None',
    },
  );
});
