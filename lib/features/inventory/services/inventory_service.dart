import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../../features/auth/services/auth_service.dart';
import '../../../shared/models/activity_log_model.dart';
import '../../products/models/product_model.dart';
import '../models/inventory_enums.dart';

class InventoryService {
  InventoryService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection(FirestoreCollections.products);

  static CollectionReference<Map<String, dynamic>> get _activityLogs =>
      _firestore.collection(FirestoreCollections.activityLogs);

  static Stream<List<ProductModel>> watchInventory() {
    return _products
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ProductModel.fromMap(doc.data(), documentId: doc.id),
              )
              .toList(),
        );
  }

  static Future<ProductModel?> getProduct(String productId) async {
    final doc = await _products.doc(productId).get();

    if (!doc.exists) {
      return null;
    }

    return ProductModel.fromMap(doc.data()!, documentId: doc.id);
  }

  static Future<void> adjustStock({
    required String productId,
    required int quantity,
    required StockDirection direction,
    required String reason,
    required String? notes,
  }) async {
    final user = AuthService.currentUser;
    final staffId = user?.uid ?? 'unknown';
    final staffName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : (user?.email ?? 'Unknown Staff');
    final now = DateTime.now();
    final productRef = _products.doc(productId);
    final logRef = _activityLogs.doc(Uuid().v4());

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(productRef);

      if (!snapshot.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message: 'Product not found.',
        );
      }

      final product = ProductModel.fromMap(
        snapshot.data()!,
        documentId: snapshot.id,
      );

      final delta = direction == StockDirection.increase ? quantity : -quantity;
      final newStock = product.stockQuantity + delta;

      if (newStock < 0) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message: 'Stock cannot go below zero.',
        );
      }

      transaction.update(productRef, {
        'stockQuantity': newStock,
        'updatedAt': Timestamp.fromDate(now),
      });

      transaction.set(
        logRef,
        ActivityLogModel(
          id: logRef.id,
          category: 'inventory',
          action: direction.name,
          productId: product.id,
          productName: product.name,
          previousStock: product.stockQuantity,
          newStock: newStock,
          difference: delta,
          reason: reason,
          notes: notes,
          staffId: staffId,
          staffName: staffName,
          createdAt: now,
        ).toMap(),
      );
    });
  }

  static Stream<List<ActivityLogModel>> watchStockHistory(String productId) {
    return _activityLogs
        .where('productId', isEqualTo: productId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    ActivityLogModel.fromMap(doc.data(), documentId: doc.id),
              )
              .toList(),
        );
  }
}
