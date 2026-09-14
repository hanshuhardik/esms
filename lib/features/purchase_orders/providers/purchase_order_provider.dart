import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/purchase_order_model.dart';
import '../repositories/purchase_order_repository.dart';

class PurchaseOrderState {
  final List<PurchaseOrderModel> orders;
  final bool isLoading;
  final String searchQuery;
  final String? errorMessage;

  static const Object _unset = Object();

  const PurchaseOrderState({
    this.orders = const [],
    this.isLoading = false,
    this.searchQuery = '',
    this.errorMessage,
  });

  PurchaseOrderState copyWith({
    List<PurchaseOrderModel>? orders,
    bool? isLoading,
    String? searchQuery,
    Object? errorMessage = _unset,
  }) {
    return PurchaseOrderState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

final purchaseOrderProvider =
    StateNotifierProvider<PurchaseOrderNotifier, PurchaseOrderState>(
      (ref) => PurchaseOrderNotifier(),
    );

class PurchaseOrderNotifier extends StateNotifier<PurchaseOrderState> {
  PurchaseOrderNotifier() : super(const PurchaseOrderState());

  StreamSubscription<List<PurchaseOrderModel>>? _subscription;
  bool _loaded = false;

  void loadPurchaseOrders({bool forceReload = false}) {
    if (_loaded && !forceReload) {
      return;
    }

    _loaded = true;
    state = state.copyWith(isLoading: true, errorMessage: null);

    _subscription?.cancel();

    _subscription = PurchaseOrderRepository.getPurchaseOrders().listen(
      (orders) {
        state = state.copyWith(
          orders: orders,
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

  List<PurchaseOrderModel> get filteredOrders {
    if (state.searchQuery.isEmpty) {
      return state.orders;
    }

    final query = state.searchQuery.toLowerCase();

    return state.orders.where((order) {
      return order.searchText.contains(query);
    }).toList();
  }

  Future<String?> addOrder(PurchaseOrderModel order) async {
    final result = await PurchaseOrderRepository.addPurchaseOrder(order);

    if (result.isFailure) {
      return result.error;
    }

    return null;
  }

  Future<String?> updateOrder(PurchaseOrderModel order) async {
    final result = await PurchaseOrderRepository.updatePurchaseOrder(order);

    if (result.isFailure) {
      return result.error;
    }

    return null;
  }

  Future<String?> deleteOrder(String orderId) async {
    final result = await PurchaseOrderRepository.deletePurchaseOrder(orderId);

    if (result.isFailure) {
      return result.error;
    }

    return null;
  }

  Future<String?> receiveOrder({
    required String orderId,
    required Map<String, int> receivedQuantities,
    String? notes,
  }) async {
    final result = await PurchaseOrderRepository.receivePurchaseOrder(
      orderId: orderId,
      receivedQuantities: receivedQuantities,
      notes: notes,
    );

    if (result.isFailure) {
      return result.error;
    }

    return null;
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

final purchaseOrderDetailsProvider =
    FutureProvider.family<PurchaseOrderModel, String>((ref, orderId) async {
      final result = await PurchaseOrderRepository.getPurchaseOrder(orderId);

      if (result.isFailure || result.data == null) {
        throw Exception(result.error ?? 'Failed to load purchase order.');
      }

      return result.data!;
    });
