import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/result.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

class ProductRepository {
  ProductRepository._();

  static Future<Result<void>> addProduct(ProductModel product) async {
    try {
      await ProductService.addProduct(product);

      return Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Failed to add product.');
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  static Future<Result<void>> updateProduct(ProductModel product) async {
    try {
      await ProductService.updateProduct(product);

      return Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Failed to update product.');
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  static Future<Result<void>> deleteProduct(String productId) async {
    try {
      await ProductService.deleteProduct(productId);

      return Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Failed to delete product.');
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  static Future<Result<ProductModel>> getProduct(String productId) async {
    try {
      final product = await ProductService.getProduct(productId);

      if (product == null) {
        return Result.failure('Product not found.');
      }

      return Result.success(product);
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Failed to fetch product.');
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  static Stream<List<ProductModel>> getProducts() {
    return ProductService.getProducts();
  }
}
