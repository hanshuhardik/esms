import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../features/products/models/product_model.dart';
import '../../products/utils/product_master_lookup.dart';
import '../models/bill_model.dart';
import '../repositories/billing_repository.dart';

class BillingCartItem {
  final String productId;
  final String productName;
  final String sku;
  final String locationName;
  final double sellingPrice;
  final double discount;
  final int quantity;
  final int availableStock;

  const BillingCartItem({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.locationName,
    required this.sellingPrice,
    required this.discount,
    required this.quantity,
    required this.availableStock,
  });

  BillingCartItem copyWith({
    String? productId,
    String? productName,
    String? sku,
    String? locationName,
    double? sellingPrice,
    double? discount,
    int? quantity,
    int? availableStock,
  }) {
    return BillingCartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      sku: sku ?? this.sku,
      locationName: locationName ?? this.locationName,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      discount: discount ?? this.discount,
      quantity: quantity ?? this.quantity,
      availableStock: availableStock ?? this.availableStock,
    );
  }

  BillItemModel toBillItem() {
    return BillItemModel(
      productId: productId,
      productName: productName,
      sku: sku,
      quantity: quantity,
      sellingPrice: sellingPrice,
      discount: discount,
    );
  }

  double get lineTotal => BillItemModel.calculateLineTotal(
    quantity: quantity,
    sellingPrice: sellingPrice,
    discount: discount,
  );
}

class BillingState {
  final String draftId;
  final List<BillingCartItem> items;
  final String searchQuery;
  final double billDiscount;
  final BillPaymentMethod paymentMethod;
  final BillPaymentStatus paymentStatus;
  final double amountPaid;
  final String customerName;
  final String customerPhone;
  final String takenBy;
  final bool isSubmitting;
  final String? errorMessage;

  static const Object _unset = Object();

  const BillingState({
    required this.draftId,
    this.items = const [],
    this.searchQuery = '',
    this.billDiscount = 0,
    this.paymentMethod = BillPaymentMethod.cash,
    this.paymentStatus = BillPaymentStatus.paid,
    this.amountPaid = 0,
    this.customerName = '',
    this.customerPhone = '',
    this.takenBy = '',
    this.isSubmitting = false,
    this.errorMessage,
  });

  BillingState copyWith({
    String? draftId,
    List<BillingCartItem>? items,
    String? searchQuery,
    double? billDiscount,
    BillPaymentMethod? paymentMethod,
    BillPaymentStatus? paymentStatus,
    double? amountPaid,
    String? customerName,
    String? customerPhone,
    String? takenBy,
    bool? isSubmitting,
    Object? errorMessage = _unset,
  }) {
    return BillingState(
      draftId: draftId ?? this.draftId,
      items: items ?? this.items,
      searchQuery: searchQuery ?? this.searchQuery,
      billDiscount: billDiscount ?? this.billDiscount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      amountPaid: amountPaid ?? this.amountPaid,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      takenBy: takenBy ?? this.takenBy,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

final billingProvider = StateNotifierProvider<BillingNotifier, BillingState>(
  (ref) => BillingNotifier(),
);

final billingDetailsProvider = FutureProvider.family<BillModel, String>((
  ref,
  billId,
) async {
  final result = await BillingRepository.getBill(billId);

  if (result.isFailure || result.data == null) {
    throw Exception(result.error ?? 'Failed to load bill.');
  }

  return result.data!;
});

class BillingNotifier extends StateNotifier<BillingState> {
  BillingNotifier() : super(BillingState(draftId: const Uuid().v4()));

  void updateSearch(String value) {
    state = state.copyWith(searchQuery: value.trim());
  }

  void updateDiscount(String value) {
    final parsed = double.tryParse(value.trim()) ?? 0;
    state = state.copyWith(
      billDiscount: parsed < 0 ? 0 : parsed,
      errorMessage: null,
    );
  }

  void setPaymentMethod(BillPaymentMethod paymentMethod) {
    state = state.copyWith(paymentMethod: paymentMethod);
  }

  void setPaymentStatus(BillPaymentStatus paymentStatus) {
    state = state.copyWith(paymentStatus: paymentStatus);
  }

  void updateAmountPaid(String value) {
    final parsed = double.tryParse(value.trim()) ?? 0;
    state = state.copyWith(
      amountPaid: parsed.clamp(0.0, total).toDouble(),
      errorMessage: null,
    );
  }

  void updateCustomerName(String value) {
    state = state.copyWith(customerName: value);
  }

  void updateCustomerPhone(String value) {
    state = state.copyWith(customerPhone: value);
  }

  void updateTakenBy(String value) {
    state = state.copyWith(takenBy: value);
  }

  String? addProduct(
    ProductModel product, {
    String? brandName,
    String? locationName,
  }) {
    if (product.status != ProductStatus.active) {
      return 'This product is inactive.';
    }

    if (product.stockQuantity <= 0) {
      return 'Insufficient stock for ${product.name}.';
    }

    final displayName = formatProductDisplayName(product.name, brandName);
    final safeLocationName = (locationName ?? '').trim();

    final index = state.items.indexWhere(
      (item) => item.productId == product.id,
    );
    if (index == -1) {
      state = state.copyWith(
        items: [
          ...state.items,
          BillingCartItem(
            productId: product.id,
            productName: displayName,
            sku: product.sku,
            locationName: safeLocationName,
            sellingPrice: product.sellingPrice,
            discount: 0,
            quantity: 1,
            availableStock: product.stockQuantity,
          ),
        ],
        errorMessage: null,
      );
      return null;
    }

    final existing = state.items[index];
    if (existing.quantity >= existing.availableStock) {
      return 'Cannot sell more than available stock for ${product.name}.';
    }

    final updatedItems = [...state.items];
    updatedItems[index] = existing.copyWith(quantity: existing.quantity + 1);
    state = state.copyWith(items: updatedItems, errorMessage: null);
    return null;
  }

  String? increaseQuantity(String productId) {
    final index = state.items.indexWhere((item) => item.productId == productId);
    if (index == -1) {
      return 'Item not found in cart.';
    }

    final item = state.items[index];
    if (item.quantity >= item.availableStock) {
      return 'Cannot sell more than available stock for ${item.productName}.';
    }

    final updatedItems = [...state.items];
    updatedItems[index] = item.copyWith(quantity: item.quantity + 1);
    state = state.copyWith(items: updatedItems, errorMessage: null);
    return null;
  }

  void decreaseQuantity(String productId) {
    final index = state.items.indexWhere((item) => item.productId == productId);
    if (index == -1) {
      return;
    }

    final item = state.items[index];
    if (item.quantity <= 1) {
      removeItem(productId);
      return;
    }

    final updatedItems = [...state.items];
    updatedItems[index] = item.copyWith(quantity: item.quantity - 1);
    state = state.copyWith(items: updatedItems);
  }

  void removeItem(String productId) {
    state = state.copyWith(
      items: state.items.where((item) => item.productId != productId).toList(),
    );
  }

  void clearCart() {
    state = BillingState(draftId: const Uuid().v4());
  }

  void setItemDiscount(String productId, double discount) {
    final index = state.items.indexWhere((item) => item.productId == productId);
    if (index == -1) {
      return;
    }

    final item = state.items[index];
    final updatedItems = [...state.items];
    updatedItems[index] = item.copyWith(discount: discount < 0 ? 0 : discount);
    state = state.copyWith(items: updatedItems);
  }

  double get subtotal {
    return state.items.fold<double>(0, (sum, item) => sum + item.lineTotal);
  }

  double get total {
    return BillModel.calculateTotal(
      subtotal: subtotal,
      discount: state.billDiscount,
    );
  }

  double get amountPaid {
    return switch (state.paymentStatus) {
      BillPaymentStatus.paid => total,
      BillPaymentStatus.due => 0,
      BillPaymentStatus.partial =>
        state.amountPaid.clamp(0.0, total).toDouble(),
    };
  }

  double get amountDue => (total - amountPaid).clamp(0.0, total).toDouble();

  String? validateForFinalize() {
    if (state.items.isEmpty) {
      return 'Add at least one item to the cart.';
    }

    if (state.billDiscount > subtotal) {
      return 'Discount cannot exceed subtotal.';
    }

    if (state.paymentStatus == BillPaymentStatus.partial &&
        (amountPaid <= 0 || amountPaid >= total)) {
      return 'Partial payment must be greater than zero and less than the total.';
    }

    return null;
  }

  Future<BillModel?> finalizeBill() async {
    final validationError = validateForFinalize();
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return null;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    final result = await BillingRepository.createBill(
      billId: state.draftId,
      items: state.items.map((item) => item.toBillItem()).toList(),
      discount: state.billDiscount,
      paymentMethod: state.paymentMethod,
      amountPaid: amountPaid,
      paymentStatus: state.paymentStatus,
      customerName: state.customerName,
      customerPhone: state.customerPhone,
      takenBy: state.takenBy,
    );

    if (result.isFailure || result.data == null) {
      state = state.copyWith(isSubmitting: false, errorMessage: result.error);
      return null;
    }

    final bill = result.data!;
    clearCart();
    return bill;
  }
}

final billingHistoryProvider =
    StateNotifierProvider<BillingHistoryNotifier, BillingHistoryState>(
      (ref) => BillingHistoryNotifier(),
    );

class BillingHistoryState {
  final List<BillModel> bills;
  final bool isLoading;
  final String searchQuery;
  final BillListFilter filter;
  final String? errorMessage;

  static const Object _unset = Object();

  const BillingHistoryState({
    this.bills = const [],
    this.isLoading = false,
    this.searchQuery = '',
    this.filter = BillListFilter.all,
    this.errorMessage,
  });

  BillingHistoryState copyWith({
    List<BillModel>? bills,
    bool? isLoading,
    String? searchQuery,
    BillListFilter? filter,
    Object? errorMessage = _unset,
  }) {
    return BillingHistoryState(
      bills: bills ?? this.bills,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

class BillingHistoryNotifier extends StateNotifier<BillingHistoryState> {
  BillingHistoryNotifier() : super(const BillingHistoryState());

  StreamSubscription<List<BillModel>>? _subscription;
  bool _loaded = false;

  void loadBills({bool forceReload = false}) {
    if (_loaded && !forceReload) {
      return;
    }

    _loaded = true;
    state = state.copyWith(isLoading: true, errorMessage: null);

    _subscription?.cancel();

    _subscription = BillingRepository.getBills().listen(
      (bills) {
        state = state.copyWith(
          bills: bills,
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

  void updateFilter(BillListFilter filter) {
    state = state.copyWith(filter: filter);
  }

  List<BillModel> get filteredBills {
    final query = state.searchQuery.toLowerCase();

    Iterable<BillModel> bills = state.bills;

    switch (state.filter) {
      case BillListFilter.paid:
        bills = bills.where((bill) => bill.amountDue == 0);
        break;
      case BillListFilter.due:
        bills = bills.where((bill) => bill.amountDue > 0);
        break;
      case BillListFilter.all:
        break;
    }

    if (query.isEmpty) {
      return bills.toList();
    }

    return bills.where((bill) => bill.searchText.contains(query)).toList();
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
