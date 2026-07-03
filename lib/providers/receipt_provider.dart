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

      // Apply Search & Filters (only for non-deleted receipts)
      final filtered = list.where((receipt) {
        if (receipt.isDeleted) return false;
        
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
      final activeList = list.where((r) => !r.isDeleted).toList();
      
      final now = DateTime.now();
      final currentMonthStart = DateTime(now.year, now.month, 1);
      final prevMonthStart = DateTime(now.year, now.month - 1, 1);
      final prevMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

      // Helper to parse purchaseDate string
      DateTime? parsePurchaseDate(String? raw) {
        if (raw == null) return null;
        final iso = DateTime.tryParse(raw);
        if (iso != null) return iso;
        final parts = raw.split(RegExp(r'[-/]'));
        if (parts.length == 3) {
          final a = int.tryParse(parts[0]);
          final b = int.tryParse(parts[1]);
          final c = int.tryParse(parts[2]);
          if (a != null && b != null && c != null) {
            if (c > 1900) {
              return DateTime.tryParse('$c-${b.toString().padLeft(2, '0')}-${a.toString().padLeft(2, '0')}');
            }
          }
        }
        return null;
      }

      double totalSpending = 0.0;
      double monthlySpending = 0.0;
      double prevMonthlySpending = 0.0;

      int totalReceipts = activeList.length;
      int monthlyReceipts = 0;

      int activeWarranties = 0;
      int expiringSoonWarranties = 0;
      int expiredWarranties = 0;

      final categoryCount = <String, int>{};
      final categorySpendingCurrent = <String, double>{};
      final categorySpendingPrev = <String, double>{};

      for (final r in activeList) {
        totalSpending += r.total;
        categoryCount[r.category] = (categoryCount[r.category] ?? 0) + 1;

        // Parse date
        final pDate = parsePurchaseDate(r.purchaseDate);
        if (pDate != null) {
          // Check if in current month
          if (pDate.year == now.year && pDate.month == now.month) {
            monthlySpending += r.total;
            monthlyReceipts++;
            categorySpendingCurrent[r.category] = (categorySpendingCurrent[r.category] ?? 0.0) + r.total;
          }
          // Check if in previous month
          else if (pDate.isAfter(prevMonthStart.subtract(const Duration(seconds: 1))) &&
                   pDate.isBefore(prevMonthEnd.add(const Duration(seconds: 1)))) {
            prevMonthlySpending += r.total;
            categorySpendingPrev[r.category] = (categorySpendingPrev[r.category] ?? 0.0) + r.total;
          }
        } else {
          // Fallback to createdAt if purchaseDate is not parseable
          if (r.createdAt != null) {
            final cDate = r.createdAt!;
            if (cDate.year == now.year && cDate.month == now.month) {
              monthlySpending += r.total;
              monthlyReceipts++;
              categorySpendingCurrent[r.category] = (categorySpendingCurrent[r.category] ?? 0.0) + r.total;
            } else if (cDate.isAfter(prevMonthStart.subtract(const Duration(seconds: 1))) &&
                       cDate.isBefore(prevMonthEnd.add(const Duration(seconds: 1)))) {
              prevMonthlySpending += r.total;
              categorySpendingPrev[r.category] = (categorySpendingPrev[r.category] ?? 0.0) + r.total;
            }
          }
        }

        // Warranty calculations
        if (r.warrantyExpiry != null) {
          final expiry = DateTime.tryParse(r.warrantyExpiry!);
          if (expiry != null) {
            if (expiry.isAfter(now)) {
              activeWarranties++;
              final daysLeft = expiry.difference(now).inDays;
              if (daysLeft <= 30) {
                expiringSoonWarranties++;
              }
            } else {
              expiredWarranties++;
            }
          }
        }
      }

      // Generate AI Insights dynamically
      final List<String> insights = [];

      // 1. Warranty Insight
      if (activeWarranties > 0) {
        insights.add('You have $activeWarranties active warranties protecting your devices.');
      } else {
        insights.add('You have 0 active warranties. Scan receipts to stay protected!');
      }

      // 2. Spending Trend Insight
      if (prevMonthlySpending > 0) {
        final diffPercent = ((monthlySpending - prevMonthlySpending) / prevMonthlySpending * 100).round();
        if (diffPercent > 0) {
          insights.add('Total spending increased by $diffPercent% compared to last month.');
        } else if (diffPercent < 0) {
          insights.add('Overall spending decreased by ${diffPercent.abs()}% compared to last month.');
        }
      }

      // 3. Category analysis (Electronics & Groceries, etc.)
      // Electronics
      final elecCurrent = categorySpendingCurrent['Electronics'] ?? 0.0;
      final elecPrev = categorySpendingPrev['Electronics'] ?? 0.0;
      if (elecPrev > 0 && elecCurrent > 0) {
        final pct = ((elecCurrent - elecPrev) / elecPrev * 100).round();
        if (pct > 0) {
          insights.add('You spent $pct% more on electronics this month.');
        } else if (pct < 0) {
          insights.add('Electronics spending decreased by ${pct.abs()}% this month.');
        }
      } else if (elecCurrent > 0 && totalSpending > 0) {
        final share = (elecCurrent / totalSpending * 100).round();
        insights.add('Electronics account for $share% of your spending this month.');
      }

      // Groceries
      final grocCurrent = categorySpendingCurrent['Groceries'] ?? 0.0;
      final grocPrev = categorySpendingPrev['Groceries'] ?? 0.0;
      if (grocPrev > 0 && grocCurrent > 0) {
        final pct = ((grocCurrent - grocPrev) / grocPrev * 100).round();
        if (pct > 0) {
          insights.add('Groceries spending increased by $pct% this month.');
        } else if (pct < 0) {
          insights.add('Groceries spending decreased by ${pct.abs()}% this month.');
        }
      } else if (grocCurrent > 0 && totalSpending > 0) {
        final share = (grocCurrent / totalSpending * 100).round();
        insights.add('Groceries represents $share% of your total spending this month.');
      }

      // 4. Frequent category
      String mostPurchasedCat = 'None';
      int maxCount = 0;
      categoryCount.forEach((cat, count) {
        if (count > maxCount) {
          maxCount = count;
          mostPurchasedCat = cat;
        }
      });
      if (mostPurchasedCat != 'None') {
        insights.add('Your most frequent purchase category is $mostPurchasedCat.');
      }

      // Average spending
      final avg = totalReceipts == 0 ? 0.0 : totalSpending / totalReceipts;
      insights.add('Your average transaction value is ₹${avg.toStringAsFixed(0)}.');

      return {
        'totalReceipts': totalReceipts,
        'monthlyReceipts': monthlyReceipts,
        'totalSpending': totalSpending,
        'monthlySpending': monthlySpending,
        'activeWarranties': activeWarranties,
        'expiringSoon': expiringSoonWarranties,
        'expiredWarranties': expiredWarranties,
        'insights': insights,
        'categoryCount': categoryCount,
        'mostPurchasedCategory': mostPurchasedCat,
      };
    },
    orElse: () => {
      'totalReceipts': 0,
      'monthlyReceipts': 0,
      'totalSpending': 0.0,
      'monthlySpending': 0.0,
      'activeWarranties': 0,
      'expiringSoon': 0,
      'expiredWarranties': 0,
      'insights': <String>[],
      'categoryCount': <String, int>{},
      'mostPurchasedCategory': 'None',
    },
  );
});

// Stream provider for deleted receipts
final trashReceiptsProvider = Provider<List<Receipt>>((ref) {
  final receiptsAsync = ref.watch(receiptsStreamProvider);
  return receiptsAsync.maybeWhen(
    data: (list) => list.where((receipt) => receipt.isDeleted).toList(),
    orElse: () => [],
  );
});
