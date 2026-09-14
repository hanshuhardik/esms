import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/activity_log_model.dart';
import '../../products/models/product_model.dart';
import '../models/inventory_enums.dart';
import '../repositories/inventory_repository.dart';

class InventoryState {
  final List<ProductModel> items;
  final bool isLoading;
  final String searchQuery;
  final String? errorMessage;

  static const Object _unset = Object();

  const InventoryState({
    this.items = const [],
    this.isLoading = false,
    this.searchQuery = '',
    this.errorMessage,
  });

  InventoryState copyWith({
    List<ProductModel>? items,
    bool? isLoading,
    String? searchQuery,
    Object? errorMessage = _unset,
  }) {
    return InventoryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, InventoryState>(
      (ref) => InventoryNotifier(),
    );

final inventoryProductProvider = FutureProvider.family<ProductModel, String>((
  ref,
  productId,
) async {
  final result = await InventoryRepository.getProduct(productId);

  if (result.isFailure || result.data == null) {
    throw Exception(result.error ?? 'Failed to load product.');
  }

  return result.data!;
});

final inventoryHistoryProvider =
    StreamProvider.family<List<ActivityLogModel>, String>((ref, productId) {
      return InventoryRepository.watchStockHistory(productId);
    });

class InventoryNotifier extends StateNotifier<InventoryState> {
  InventoryNotifier() : super(const InventoryState());

  StreamSubscription<List<ProductModel>>? _subscription;
  bool _loaded = false;

  void loadInventory({bool forceReload = false}) {
    if (_loaded && !forceReload) {
      return;
    }

    _loaded = true;

    state = state.copyWith(isLoading: true, errorMessage: null);

    _subscription?.cancel();

    _subscription = InventoryRepository.watchInventory().listen(
      (items) {
        state = state.copyWith(
          items: items,
          isLoading: false,
          errorMessage: null,
        );
      },
      onError: (Object error) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _messageForError(error),
        );
        _loaded = false;
      },
    );
  }

  void updateSearch(String value) {
    state = state.copyWith(searchQuery: value.trim());
  }

  List<ProductModel> filteredItems(InventoryListFilter filter) {
    final query = state.searchQuery.toLowerCase();

    Iterable<ProductModel> items = state.items;

    switch (filter) {
      case InventoryListFilter.lowStock:
        items = items.where((item) => item.isLowStock);
        break;
      case InventoryListFilter.outOfStock:
        items = items.where((item) => item.isOutOfStock);
        break;
      case InventoryListFilter.all:
        break;
    }

    if (query.isEmpty) {
      return items.toList();
    }

    return items.where((product) {
      return product.name.toLowerCase().contains(query) ||
          product.sku.toLowerCase().contains(query);
    }).toList();
  }

  List<ProductModel> get lowStockItems =>
      state.items.where((item) => item.isLowStock).toList();

  List<ProductModel> get outOfStockItems =>
      state.items.where((item) => item.isOutOfStock).toList();

  List<ProductModel> get inStockItems =>
      state.items.where((item) => item.isInStock).toList();

  Future<String?> adjustStock({
    required String productId,
    required int quantity,
    required StockDirection direction,
    required String reason,
    required String? notes,
  }) async {
    final result = await InventoryRepository.adjustStock(
      productId: productId,
      quantity: quantity,
      direction: direction,
      reason: reason,
      notes: notes,
    );

    if (result.isFailure) {
      return result.error;
    }

    return null;
  }

  Future<String?> increaseStock({
    required String productId,
    required int quantity,
    required String reason,
    required String? notes,
  }) {
    return adjustStock(
      productId: productId,
      quantity: quantity,
      direction: StockDirection.increase,
      reason: reason,
      notes: notes,
    );
  }

  Future<String?> decreaseStock({
    required String productId,
    required int quantity,
    required String reason,
    required String? notes,
  }) {
    return adjustStock(
      productId: productId,
      quantity: quantity,
      direction: StockDirection.decrease,
      reason: reason,
      notes: notes,
    );
  }

  String _messageForError(Object error) {
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }

    return error.toString();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
