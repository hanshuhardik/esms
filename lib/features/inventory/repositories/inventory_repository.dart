import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/result.dart';
import '../../../shared/models/activity_log_model.dart';
import '../../products/models/product_model.dart';
import '../models/inventory_enums.dart';
import '../services/inventory_service.dart';

class InventoryRepository {
  InventoryRepository._();

  static Stream<List<ProductModel>> watchInventory() {
    return InventoryService.watchInventory();
  }

  static Future<Result<ProductModel>> getProduct(String productId) async {
    try {
      final product = await InventoryService.getProduct(productId);

      if (product == null) {
        return Result.failure('Product not found.');
      }

      return Result.success(product);
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Failed to load product.');
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  static Future<Result<void>> adjustStock({
    required String productId,
    required int quantity,
    required StockDirection direction,
    required String reason,
    required String? notes,
  }) async {
    try {
      await InventoryService.adjustStock(
        productId: productId,
        quantity: quantity,
        direction: direction,
        reason: reason,
        notes: notes,
      );

      return Result.success();
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Failed to adjust stock.');
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  static Stream<List<ActivityLogModel>> watchStockHistory(String productId) {
    return InventoryService.watchStockHistory(productId);
  }
}
