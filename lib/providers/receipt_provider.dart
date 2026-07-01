import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/receipt.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

final receiptServiceProvider = Provider<ReceiptService>((ref) {
  final authState = ref.watch(authProvider);

  return authState.when(
    data: (user) {
      if (user == null) return MockReceiptService();
      return FirestoreReceiptService(userId: user.uid);
    },
    loading: () => MockReceiptService(),
    error: (_, __) => MockReceiptService(),
  );
});

class ReceiptListNotifier extends StateNotifier<AsyncValue<List<Receipt>>> {
  final ReceiptService _service;

  ReceiptListNotifier(this._service) : super(const AsyncValue.loading()) {
    loadReceipts();
  }

  Future<void> loadReceipts() async {
    try {
      final list = await _service.getReceipts();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addReceipt(Receipt receipt) async {
    state.whenData((currentList) async {
      state = AsyncValue.data([receipt, ...currentList]);
      try {
        await _service.saveReceipt(receipt);
      } catch (e) {
        // Fallback or reload if error
        loadReceipts();
      }
    });
  }

  Future<void> deleteReceipt(String id) async {
    state.whenData((currentList) async {
      state = AsyncValue.data(currentList.where((r) => r.id != id).toList());
      try {
        await _service.deleteReceipt(id);
      } catch (e) {
        loadReceipts();
      }
    });
  }

  Future<void> toggleFavorite(String id) async {
    state.whenData((currentList) async {
      state = AsyncValue.data(currentList.map((r) {
        if (r.id == id) return r.copyWith(isFavorite: !r.isFavorite);
        return r;
      }).toList());
      try {
        await _service.toggleFavorite(id);
      } catch (e) {
        loadReceipts();
      }
    });
  }

  Future<void> toggleArchive(String id) async {
    state.whenData((currentList) async {
      state = AsyncValue.data(currentList.map((r) {
        if (r.id == id) return r.copyWith(isArchived: !r.isArchived);
        return r;
      }).toList());
      try {
        await _service.toggleArchive(id);
      } catch (e) {
        loadReceipts();
      }
    });
  }
}

final receiptsProvider =
    StateNotifierProvider<ReceiptListNotifier, AsyncValue<List<Receipt>>>((ref) {
  final service = ref.watch(receiptServiceProvider);
  return ReceiptListNotifier(service);
});

// Search & Filtering State Providers
final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedCategoryFilterProvider = StateProvider<String?>((ref) => null);

final filteredReceiptsProvider = Provider<List<Receipt>>((ref) {
  final receiptsAsync = ref.watch(receiptsProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final selectedCategory = ref.watch(selectedCategoryFilterProvider);

  return receiptsAsync.maybeWhen(
    data: (list) {
      return list.where((receipt) {
        final matchesSearch = receipt.merchant.toLowerCase().contains(query) ||
            receipt.items.any((item) => item.name.toLowerCase().contains(query)) ||
            (receipt.notes != null && receipt.notes!.toLowerCase().contains(query));

        final matchesCategory = selectedCategory == null || receipt.category == selectedCategory;

        return matchesSearch && matchesCategory && !receipt.isArchived;
      }).toList();
    },
    orElse: () => [],
  );
});
