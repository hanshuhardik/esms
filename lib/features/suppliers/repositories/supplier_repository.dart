import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/supplier_model.dart';
import '../models/supplier_validator.dart';
import '../services/supplier_service.dart';
import '../../staff/models/authorization.dart';
import '../../staff/models/permission.dart';
import '../../../shared/models/user_model.dart';
import '../../../core/utils/result.dart';

class SupplierRepository {
  SupplierRepository._();

  static Stream<List<SupplierModel>> getSuppliers() {
    try {
      return SupplierService.watchSuppliers();
    } on FirebaseException catch (e) {
      return Stream.error(e.message ?? 'Failed to fetch suppliers.');
    } catch (e) {
      return Stream.error(e.toString());
    }
  }

  static Future<Result<SupplierModel?>> getSupplier(String id) async {
    try {
      return Result.success(await SupplierService.getSupplier(id));
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Failed to fetch supplier.');
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  static Future<Result<SupplierModel>> createSupplier({
    required SupplierModel supplier,
    required UserModel currentUser,
  }) async {
    final error = _authorizeAndValidate(supplier, currentUser);
    if (error != null) return Result.failure(error);
    try {
      return Result.success(await SupplierService.createSupplier(supplier));
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Failed to create supplier.');
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  static Future<Result<SupplierModel>> updateSupplier({
    required SupplierModel supplier,
    required UserModel currentUser,
  }) async {
    final error = _authorizeAndValidate(supplier, currentUser);
    if (error != null) return Result.failure(error);
    try {
      return Result.success(await SupplierService.updateSupplier(supplier));
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Failed to update supplier.');
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  static String? _authorizeAndValidate(
    SupplierModel supplier,
    UserModel currentUser,
  ) {
    if (!Authorization.can(currentUser, Permission.manageSuppliers)) {
      return 'You are not authorized to manage suppliers.';
    }
    return SupplierValidator.validateName(supplier.name) ??
        SupplierValidator.validatePhone(supplier.phone) ??
        SupplierValidator.validateEmail(supplier.email);
  }

  static List<SupplierModel> filterSuppliers(
    List<SupplierModel> suppliers, {
    String searchQuery = '',
    bool? active,
  }) {
    final query = searchQuery.trim().toLowerCase();
    return suppliers.where((supplier) {
      final matchesStatus = active == null || supplier.isActive == active;
      final matchesSearch =
          query.isEmpty ||
          '${supplier.name} ${supplier.contactPerson} ${supplier.phone} '
                  '${supplier.email} ${supplier.gstNumber}'
              .toLowerCase()
              .contains(query);
      return matchesStatus && matchesSearch;
    }).toList();
  }
}
