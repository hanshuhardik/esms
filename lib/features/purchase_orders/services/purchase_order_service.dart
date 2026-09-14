import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../../features/auth/services/auth_service.dart';
import '../../../shared/models/activity_log_model.dart';
import '../../products/models/product_model.dart';
import '../models/purchase_order_model.dart';

class PurchaseOrderService {
  PurchaseOrderService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _purchaseOrders =>
      _firestore.collection(FirestoreCollections.purchaseOrders);

  static CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection(FirestoreCollections.products);

  static CollectionReference<Map<String, dynamic>> get _activityLogs =>
      _firestore.collection(FirestoreCollections.activityLogs);

  static Stream<List<PurchaseOrderModel>> watchPurchaseOrders() {
    return _purchaseOrders
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    PurchaseOrderModel.fromMap(doc.data(), documentId: doc.id),
              )
              .toList(),
        );
  }

  static Future<PurchaseOrderModel?> getPurchaseOrder(String orderId) async {
    final doc = await _purchaseOrders.doc(orderId).get();

    if (!doc.exists) {
      return null;
    }

    return PurchaseOrderModel.fromMap(doc.data()!, documentId: doc.id);
  }

  static Future<void> addPurchaseOrder(PurchaseOrderModel order) async {
    await _purchaseOrders.doc(order.id).set(order.toMap());
  }

  static Future<void> updatePurchaseOrder(PurchaseOrderModel order) async {
    await _purchaseOrders.doc(order.id).update(order.toMap());
  }

  static Future<void> deletePurchaseOrder(String orderId) async {
    await _purchaseOrders.doc(orderId).delete();
  }

  static Future<void> receivePurchaseOrder({
    required String orderId,
    required Map<String, int> receivedQuantities,
    String? notes,
  }) async {
    final user = AuthService.currentUser;
    final staffId = user?.uid ?? 'unknown';
    final staffName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : (user?.email ?? 'Unknown Staff');
    final now = DateTime.now();
    final orderRef = _purchaseOrders.doc(orderId);

    await _firestore.runTransaction((transaction) async {
      final orderSnapshot = await transaction.get(orderRef);

      if (!orderSnapshot.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message: 'Purchase order not found.',
        );
      }

      final order = PurchaseOrderModel.fromMap(
        orderSnapshot.data()!,
        documentId: orderSnapshot.id,
      );

      if (order.status == PurchaseOrderStatus.cancelled ||
          order.status == PurchaseOrderStatus.completed) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message: 'This purchase order cannot be received.',
        );
      }

      final updatedItems = <PurchaseOrderItemModel>[];
      var anyReceived = false;
      var allCompleted = true;

      for (final item in order.items) {
        final requestedQuantity =
            receivedQuantities[item.id] ?? item.remainingQuantity;
        final quantityToReceive = PurchaseOrderModel.clampReceivedQuantity(
          requestedQuantity: requestedQuantity,
          remainingQuantity: item.remainingQuantity,
        );

        if (quantityToReceive > 0) {
          anyReceived = true;
          final productRef = _products.doc(item.productId);
          final productSnapshot = await transaction.get(productRef);

          if (!productSnapshot.exists) {
            throw FirebaseException(
              plugin: 'cloud_firestore',
              message: 'Product not found for ${item.productName}.',
            );
          }

          final product = ProductModel.fromMap(
            productSnapshot.data()!,
            documentId: productSnapshot.id,
          );
          final previousStock = product.stockQuantity;
          final newStock = previousStock + quantityToReceive;

          transaction.update(productRef, {
            'stockQuantity': newStock,
            'updatedAt': Timestamp.fromDate(now),
          });

          final logRef = _activityLogs.doc(const Uuid().v4());
          transaction.set(
            logRef,
            ActivityLogModel(
              id: logRef.id,
              category: 'inventory',
              action: 'purchase_order_receive',
              productId: product.id,
              productName: product.name,
              previousStock: previousStock,
              newStock: newStock,
              difference: quantityToReceive,
              reason: 'Received via purchase order ${order.orderNumber}',
              notes: notes,
              staffId: staffId,
              staffName: staffName,
              createdAt: now,
            ).toMap(),
          );
        }

        final receivedQuantity = item.quantityReceived + quantityToReceive;
        if (receivedQuantity < item.quantityOrdered) {
          allCompleted = false;
        }

        updatedItems.add(
          item.copyWith(quantityReceived: receivedQuantity, updatedAt: now),
        );
      }

      final nextStatus = PurchaseOrderModel.resolveStatusAfterReceive(
        currentStatus: order.status,
        anyReceived: anyReceived,
        allCompleted: allCompleted,
      );

      transaction.update(
        orderRef,
        order
            .copyWith(
              items: updatedItems,
              status: nextStatus,
              notes: notes == null || notes.trim().isEmpty
                  ? order.notes
                  : notes,
              receivedById: anyReceived ? staffId : order.receivedById,
              receivedByName: anyReceived ? staffName : order.receivedByName,
              receivedAt: nextStatus == PurchaseOrderStatus.completed
                  ? now
                  : order.receivedAt,
              updatedAt: now,
            )
            .toMap(),
      );
    });
  }
}
