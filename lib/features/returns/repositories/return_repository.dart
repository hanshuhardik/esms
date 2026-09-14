import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/result.dart';
import '../../billing/models/bill_model.dart';
import '../models/return_model.dart';
import '../services/return_service.dart';

class ReturnRepository {
  ReturnRepository._();

  static Future<Result<List<BillModel>>> getCustomerBills(String phone) async {
    try {
      return Result.success(await ReturnService.getCustomerBills(phone));
    } on FirebaseException catch (error) {
      return Result.failure(error.message ?? 'Failed to find customer bills.');
    } catch (_) {
      return Result.failure('Failed to find customer bills.');
    }
  }

  static Future<Result<List<ReturnModel>>> getCustomerReturns(
    List<String> billIds,
  ) async {
    try {
      return Result.success(await ReturnService.getCustomerReturns(billIds));
    } on FirebaseException catch (error) {
      return Result.failure(
        error.message ?? 'Failed to load previous returns.',
      );
    } catch (_) {
      return Result.failure('Failed to load previous returns.');
    }
  }

  static Future<Result<ReturnModel>> getReturn(String returnId) async {
    try {
      final result = await ReturnService.getReturn(returnId);
      if (result == null) return Result.failure('Return not found.');
      return Result.success(result);
    } on FirebaseException catch (error) {
      return Result.failure(error.message ?? 'Failed to load return.');
    } catch (_) {
      return Result.failure('Failed to load return.');
    }
  }

  static Stream<List<ReturnModel>> watchReturns() {
    return ReturnService.watchReturns();
  }

  static Future<Result<ReturnModel>> createReturn({
    required String customerPhone,
    String? customerName,
    required List<ReturnItem> items,
  }) async {
    try {
      return Result.success(
        await ReturnService.createReturn(
          customerPhone: customerPhone,
          customerName: customerName,
          items: items,
        ),
      );
    } on FirebaseException catch (error) {
      return Result.failure(error.message ?? 'Failed to process return.');
    } catch (_) {
      return Result.failure('Failed to process return.');
    }
  }
}
