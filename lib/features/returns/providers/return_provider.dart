import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../billing/models/bill_model.dart';
import '../models/return_model.dart';
import '../repositories/return_repository.dart';

final customerBillsProvider = FutureProvider.family<List<BillModel>, String>((
  ref,
  phone,
) async {
  final result = await ReturnRepository.getCustomerBills(phone);
  if (result.isFailure) throw Exception(result.error);
  return result.data ?? const [];
});

final customerReturnsProvider =
    FutureProvider.family<List<ReturnModel>, String>((ref, billIdsKey) async {
      final billIds = billIdsKey
          .split('|')
          .where((value) => value.trim().isNotEmpty)
          .toList();
      final result = await ReturnRepository.getCustomerReturns(billIds);
      if (result.isFailure) throw Exception(result.error);
      return result.data ?? const [];
    });

final returnDetailsProvider = FutureProvider.family<ReturnModel, String>((
  ref,
  returnId,
) async {
  final result = await ReturnRepository.getReturn(returnId);
  if (result.isFailure || result.data == null) {
    throw Exception(result.error ?? 'Return not found.');
  }
  return result.data!;
});

final returnsProvider = StreamProvider<List<ReturnModel>>((ref) {
  return ReturnRepository.watchReturns();
});

class ReturnState {
  final bool isCreating;
  final ReturnModel? createdReturn;
  final String? errorMessage;

  const ReturnState({
    this.isCreating = false,
    this.createdReturn,
    this.errorMessage,
  });

  ReturnState copyWith({
    bool? isCreating,
    ReturnModel? createdReturn,
    String? errorMessage,
    bool clearError = false,
    bool clearCreatedReturn = false,
  }) {
    return ReturnState(
      isCreating: isCreating ?? this.isCreating,
      createdReturn: clearCreatedReturn
          ? null
          : createdReturn ?? this.createdReturn,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final returnNotifierProvider =
    StateNotifierProvider<ReturnNotifier, ReturnState>(
      (ref) => ReturnNotifier(),
    );

class ReturnNotifier extends StateNotifier<ReturnState> {
  ReturnNotifier() : super(const ReturnState());

  Future<ReturnModel?> create({
    required String customerPhone,
    String? customerName,
    required List<ReturnItem> items,
  }) async {
    state = state.copyWith(
      isCreating: true,
      clearError: true,
      clearCreatedReturn: true,
    );

    final result = await ReturnRepository.createReturn(
      customerPhone: customerPhone,
      customerName: customerName,
      items: items,
    );

    if (result.isFailure || result.data == null) {
      state = state.copyWith(
        isCreating: false,
        errorMessage: result.error ?? 'Failed to process return.',
      );
      return null;
    }

    state = state.copyWith(
      isCreating: false,
      createdReturn: result.data,
      clearError: true,
    );
    return result.data;
  }

  void clear() {
    state = const ReturnState();
  }
}
