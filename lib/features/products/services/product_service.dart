import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_collections.dart';
import '../models/product_model.dart';

class ProductService {
  ProductService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection(FirestoreCollections.products);

  static Future<void> addProduct(ProductModel product) async {
    await _products.doc(product.id).set(product.toMap());
  }

  static Future<void> updateProduct(ProductModel product) async {
    await _products.doc(product.id).update(product.toMap());
  }

  static Future<void> deleteProduct(String id) async {
    await _products.doc(id).delete();
  }

  static Stream<List<ProductModel>> getProducts() {
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

  static Future<ProductModel?> getProduct(String id) async {
    final doc = await _products.doc(id).get();

    if (!doc.exists) {
      return null;
    }

    return ProductModel.fromMap(doc.data()!, documentId: doc.id);
  }
}
