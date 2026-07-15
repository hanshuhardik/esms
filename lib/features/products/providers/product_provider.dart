import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product_model.dart';
import '../repositories/product_repository.dart';

class ProductState {
  final List<ProductModel> products;
  final bool isLoading;
  final String searchQuery;
  final String? errorMessage;

  static const Object _unset = Object();

  const ProductState({
    this.products = const [],
    this.isLoading = false,
    this.searchQuery = '',
    this.errorMessage,
  });

  ProductState copyWith({
    List<ProductModel>? products,
    bool? isLoading,
    String? searchQuery,
    Object? errorMessage = _unset,
  }) {
    return ProductState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

final productProvider = StateNotifierProvider<ProductNotifier, ProductState>(
  (ref) => ProductNotifier(),
);

class ProductNotifier extends StateNotifier<ProductState> {
  ProductNotifier() : super(const ProductState());

  StreamSubscription<List<ProductModel>>? _subscription;

  bool _loaded = false;

  /// Load all products from Firestore
  void loadProducts({bool forceReload = false}) {
    if (_loaded && !forceReload) {
      return;
    }

    _loaded = true;

    state = state.copyWith(isLoading: true, errorMessage: null);

    _subscription?.cancel();

    _subscription = ProductRepository.getProducts().listen(
      (products) {
        state = state.copyWith(
          products: products,
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

  /// Update search query
  void updateSearch(String value) {
    state = state.copyWith(searchQuery: value.trim());
  }

  /// Filter products locally
  List<ProductModel> get filteredProducts {
    if (state.searchQuery.isEmpty) {
      return state.products;
    }

    final query = state.searchQuery.toLowerCase();

    return state.products.where((product) {
      return product.name.toLowerCase().contains(query) ||
          product.sku.toLowerCase().contains(query);
    }).toList();
  }

  Future<String?> addProduct(ProductModel product) async {
    final result = await ProductRepository.addProduct(product);

    if (result.isFailure) {
      return result.error;
    }

    return null;
  }

  Future<String?> updateProduct(ProductModel product) async {
    final result = await ProductRepository.updateProduct(product);

    if (result.isFailure) {
      return result.error;
    }

    return null;
  }

  Future<String?> deleteProduct(String productId) async {
    final result = await ProductRepository.deleteProduct(productId);

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

final productDetailsProvider = FutureProvider.family<ProductModel, String>((
  ref,
  productId,
) async {
  final result = await ProductRepository.getProduct(productId);

  if (result.isFailure || result.data == null) {
    throw Exception(result.error ?? 'Failed to load product.');
  }

  return result.data!;
});
