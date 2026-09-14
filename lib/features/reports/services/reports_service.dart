import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../billing/models/bill_model.dart';
import '../../expenses/models/expense_model.dart';
import '../../products/models/product_model.dart';
import '../../purchase_orders/models/purchase_order_model.dart';

class ReportsService {
  ReportsService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _bills =>
      _firestore.collection(FirestoreCollections.bills);

  static CollectionReference<Map<String, dynamic>> get _expenses =>
      _firestore.collection(FirestoreCollections.expenses);

  static CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection(FirestoreCollections.products);

  static CollectionReference<Map<String, dynamic>> get _purchaseOrders =>
      _firestore.collection(FirestoreCollections.purchaseOrders);

  static Future<List<BillModel>> fetchBills() async {
    final snapshot = await _bills.orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((doc) => BillModel.fromMap(doc.data(), documentId: doc.id))
        .toList();
  }

  static Future<List<ExpenseModel>> fetchExpenses() async {
    final snapshot = await _expenses
        .orderBy('expenseDate', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ExpenseModel.fromMap(doc.data(), documentId: doc.id))
        .toList();
  }

  static Future<List<ProductModel>> fetchProducts() async {
    final snapshot = await _products.orderBy('name').get();
    return snapshot.docs
        .map((doc) => ProductModel.fromMap(doc.data(), documentId: doc.id))
        .toList();
  }

  static Future<List<PurchaseOrderModel>> fetchPurchaseOrders() async {
    final snapshot = await _purchaseOrders
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map(
          (doc) => PurchaseOrderModel.fromMap(doc.data(), documentId: doc.id),
        )
        .toList();
  }
}
