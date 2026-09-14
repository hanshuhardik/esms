import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/supplier_model.dart';
import '../repositories/supplier_repository.dart';
import '../../../shared/models/user_model.dart';

final suppliersProvider = StreamProvider<List<SupplierModel>>((ref) {
  return SupplierRepository.getSuppliers();
});

final supplierDetailsProvider = FutureProvider.family<SupplierModel?, String>((
  ref,
  id,
) async {
  final result = await SupplierRepository.getSupplier(id);
  if (result.isFailure) throw Exception(result.error);
  return result.data;
});

class SupplierNotifier extends StateNotifier<AsyncValue<void>> {
  SupplierNotifier() : super(const AsyncData(null));

  Future<String?> create(SupplierModel supplier, UserModel user) async {
    state = const AsyncLoading();
    final result = await SupplierRepository.createSupplier(
      supplier: supplier,
      currentUser: user,
    );
    state = result.isSuccess
        ? const AsyncData(null)
        : AsyncError(result.error!, StackTrace.current);
    return result.error;
  }

  Future<String?> update(SupplierModel supplier, UserModel user) async {
    state = const AsyncLoading();
    final result = await SupplierRepository.updateSupplier(
      supplier: supplier,
      currentUser: user,
    );
    state = result.isSuccess
        ? const AsyncData(null)
        : AsyncError(result.error!, StackTrace.current);
    return result.error;
  }
}

final supplierNotifierProvider =
    StateNotifierProvider<SupplierNotifier, AsyncValue<void>>(
      (ref) => SupplierNotifier(),
    );
