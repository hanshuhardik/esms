import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/result.dart';
import '../models/bill_model.dart';
import '../services/billing_service.dart';

class BillingRepository {
  BillingRepository._();

  static Stream<List<BillModel>> getBills() {
    return BillingService.watchBills();
  }

  static Future<Result<BillModel>> getBill(String billId) async {
    try {
      final bill = await BillingService.getBill(billId);

      if (bill == null) {
        return Result.failure('Bill not found.');
      }

      return Result.success(bill);
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Failed to fetch bill.');
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  static Future<Result<BillModel>> createBill({
    required String billId,
    required List<BillItemModel> items,
    required double discount,
    required BillPaymentMethod paymentMethod,
    required double amountPaid,
    required BillPaymentStatus paymentStatus,
    String? customerName,
    String? customerPhone,
    String? takenBy,
  }) async {
    try {
      final bill = await BillingService.createBill(
        billId: billId,
        items: items,
        discount: discount,
        paymentMethod: paymentMethod,
        amountPaid: amountPaid,
        paymentStatus: paymentStatus,
        customerName: customerName,
        customerPhone: customerPhone,
        takenBy: takenBy,
      );

      return Result.success(bill);
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Failed to create bill.');
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  static Future<Result<BillModel>> updateBill({
    required String billId,
    required double discount,
    required double amountPaid,
    required BillPaymentStatus paymentStatus,
    String? customerPhone,
    String? takenBy,
  }) async {
    try {
      return Result.success(
        await BillingService.updateBill(
          billId: billId,
          discount: discount,
          amountPaid: amountPaid,
          paymentStatus: paymentStatus,
          customerPhone: customerPhone,
          takenBy: takenBy,
        ),
      );
    } on FirebaseException catch (error) {
      return Result.failure(error.message ?? 'Failed to update bill.');
    } catch (error) {
      return Result.failure(error.toString());
    }
  }

  static Future<Result<BillModel>> collectDuePayment({
    required String billId,
    required double amountReceived,
  }) async {
    try {
      return Result.success(
        await BillingService.collectDuePayment(
          billId: billId,
          amountReceived: amountReceived,
        ),
      );
    } on FirebaseException catch (error) {
      return Result.failure(error.message ?? 'Failed to collect payment.');
    } catch (error) {
      return Result.failure(error.toString());
    }
  }
}
