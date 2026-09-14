import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/result.dart';
import '../models/purchase_order_model.dart';
import '../services/purchase_order_service.dart';

class PurchaseOrderRepository {
  PurchaseOrderRepository._();

  static Future<Result<void>> addPurchaseOrder(PurchaseOrderModel order) async {
    try {
      await PurchaseOrderService.addPurchaseOrder(order);
      return Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Failed to add purchase order.');
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  static Future<Result<void>> updatePurchaseOrder(
    PurchaseOrderModel order,
  ) async {
    try {
      await PurchaseOrderService.updatePurchaseOrder(order);
      return Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Failed to update purchase order.');
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  static Future<Result<void>> deletePurchaseOrder(String orderId) async {
    try {
      await PurchaseOrderService.deletePurchaseOrder(orderId);
      return Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Failed to delete purchase order.');
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  static Future<Result<PurchaseOrderModel>> getPurchaseOrder(
    String orderId,
  ) async {
    try {
      final order = await PurchaseOrderService.getPurchaseOrder(orderId);

      if (order == null) {
        return Result.failure('Purchase order not found.');
      }

      return Result.success(order);
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Failed to fetch purchase order.');
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  static Future<Result<void>> receivePurchaseOrder({
    required String orderId,
    required Map<String, int> receivedQuantities,
    String? notes,
  }) async {
    try {
      await PurchaseOrderService.receivePurchaseOrder(
        orderId: orderId,
        receivedQuantities: receivedQuantities,
        notes: notes,
      );
      return Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Failed to receive purchase order.');
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  static Stream<List<PurchaseOrderModel>> getPurchaseOrders() {
    return PurchaseOrderService.watchPurchaseOrders();
  }
}
