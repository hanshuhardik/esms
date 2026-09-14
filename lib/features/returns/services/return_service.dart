import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../../features/billing/models/bill_model.dart';
import '../../../features/auth/services/auth_service.dart';
import '../../../shared/models/activity_log_model.dart';
import '../../products/models/product_model.dart';
import '../models/return_model.dart';

class ReturnService {
  ReturnService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _bills =>
      _firestore.collection(FirestoreCollections.bills);

  static CollectionReference<Map<String, dynamic>> get _returns =>
      _firestore.collection(FirestoreCollections.returns);

  static CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection(FirestoreCollections.products);

  static CollectionReference<Map<String, dynamic>> get _activityLogs =>
      _firestore.collection(FirestoreCollections.activityLogs);

  static Future<List<BillModel>> getCustomerBills(String phone) async {
    final normalizedPhone = _normalizePhone(phone);
    if (normalizedPhone.isEmpty) return const [];

    final snapshot = await _bills
        .where('customerPhone', isEqualTo: normalizedPhone)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => BillModel.fromMap(doc.data(), documentId: doc.id))
        .where((bill) => bill.status == BillStatus.completed)
        .toList();
  }

  static Future<List<ReturnModel>> getCustomerReturns(
    List<String> billIds,
  ) async {
    final ids = billIds.where((id) => id.trim().isNotEmpty).toSet().toList();
    if (ids.isEmpty) return const [];

    final results = <String, ReturnModel>{};
    for (var offset = 0; offset < ids.length; offset += 10) {
      final chunk = ids.skip(offset).take(10).toList();
      final snapshot = await _returns
          .where('originalBillIds', arrayContainsAny: chunk)
          .get();
      for (final doc in snapshot.docs) {
        results[doc.id] = ReturnModel.fromMap(doc.data(), documentId: doc.id);
      }
    }

    return results.values.toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
  }

  static Future<ReturnModel?> getReturn(String returnId) async {
    final doc = await _returns.doc(returnId).get();
    if (!doc.exists) return null;
    return ReturnModel.fromMap(doc.data()!, documentId: doc.id);
  }

  static Stream<List<ReturnModel>> watchReturns() {
    return _returns
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ReturnModel.fromMap(doc.data(), documentId: doc.id))
              .toList(),
        );
  }

  static Future<ReturnModel> createReturn({
    required String customerPhone,
    String? customerName,
    required List<ReturnItem> items,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'unauthenticated',
        message: 'User must be signed in to process a return.',
      );
    }

    final profile = await _firestore
        .collection(FirestoreCollections.users)
        .doc(user.uid)
        .get();
    final role = profile.data()?['role']?.toString();
    final active = profile.data()?['isActive'] == true;
    if (!active || (role != 'owner' && role != 'staff')) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'User is not authorized to process returns.',
      );
    }

    final normalizedPhone = _normalizePhone(customerPhone);
    if (items.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-argument',
        message: 'Please select at least one product.',
      );
    }

    final billIds = items.map((item) => item.originalBillId).toSet().toList();
    final previousReturnQuery = await _returns
        .where('originalBillIds', arrayContainsAny: billIds)
        .get();
    final previousReturnRefs = previousReturnQuery.docs
        .map((doc) => doc.reference)
        .toList();
    final returnId = const Uuid().v4();
    final now = DateTime.now();
    final returnRef = _returns.doc(returnId);
    final staffName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : (user.email ?? 'Unknown Staff');

    return _firestore.runTransaction((transaction) async {
      final previousReturns = <ReturnModel>[];
      for (final previousReturnRef in previousReturnRefs) {
        final snapshot = await transaction.get(previousReturnRef);
        if (snapshot.exists) {
          previousReturns.add(
            ReturnModel.fromMap(snapshot.data()!, documentId: snapshot.id),
          );
        }
      }
      final billSnapshots = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final billId in billIds) {
        final snapshot = await transaction.get(_bills.doc(billId));
        billSnapshots[billId] = snapshot;
      }

      final returnedBySource = <String, int>{};
      final consumedDiscountByBill = <String, double>{};
      for (final previous in previousReturns) {
        for (final item in previous.items) {
          final key = _sourceKey(item.originalBillId, item.originalItemIndex);
          returnedBySource[key] = (returnedBySource[key] ?? 0) + item.quantity;
        }

        if (previous.discountAllocations.isNotEmpty) {
          previous.discountAllocations.forEach((billId, amount) {
            consumedDiscountByBill[billId] =
                (consumedDiscountByBill[billId] ?? 0.0) + amount;
          });
        } else if (previous.discount > 0 &&
            previous.originalBillIds.isNotEmpty) {
          // Legacy return records do not identify per-bill consumption. Treat
          // all referenced bills as consumed to prevent duplicate discounts.
          for (final billId in previous.originalBillIds) {
            consumedDiscountByBill[billId] = double.infinity;
          }
        }
      }

      final productSnapshots =
          <String, DocumentSnapshot<Map<String, dynamic>>>{};
      final quantitiesByProduct = <String, int>{};
      final normalizedItems = <ReturnItem>[];
      final seenSources = <String>{};
      var subtotal = 0.0;

      for (final item in items) {
        if (!seenSources.add(
          _sourceKey(item.originalBillId, item.originalItemIndex),
        )) {
          throw _invalid('Duplicate source bill item.');
        }
        if (item.quantity <= 0) {
          throw _invalid('Return quantity must be greater than zero.');
        }

        final billSnapshot = billSnapshots[item.originalBillId];
        if (billSnapshot == null || !billSnapshot.exists) {
          throw _notFound('Original bill not found.');
        }
        final bill = BillModel.fromMap(
          billSnapshot.data()!,
          documentId: billSnapshot.id,
        );
        if (bill.status != BillStatus.completed) {
          throw _invalid('Only completed bills can be returned.');
        }
        if (item.originalItemIndex < 0 ||
            item.originalItemIndex >= bill.items.length) {
          throw _invalid('Original bill item was not found.');
        }

        final sourceItem = bill.items[item.originalItemIndex];
        if (sourceItem.productId != item.productId) {
          throw _invalid('Return product does not match the original bill.');
        }
        final alreadyReturned =
            returnedBySource[_sourceKey(
              item.originalBillId,
              item.originalItemIndex,
            )] ??
            0;
        final remaining = sourceItem.quantity - alreadyReturned;
        if (item.quantity > remaining) {
          throw _invalid('Return quantity cannot exceed available quantity.');
        }

        final unitPrice = sourceItem.sellingPrice;
        final total = item.quantity * unitPrice;
        final normalizedItem = item.copyWith(
          originalBillId: bill.id,
          productId: sourceItem.productId,
          productName: sourceItem.productName,
          unitPrice: unitPrice,
          total: total,
        );
        normalizedItems.add(normalizedItem);
        subtotal += total;
        quantitiesByProduct[sourceItem.productId] =
            (quantitiesByProduct[sourceItem.productId] ?? 0) + item.quantity;
      }

      for (final productId in quantitiesByProduct.keys) {
        final snapshot = await transaction.get(_products.doc(productId));
        productSnapshots[productId] = snapshot;
      }

      final discountAllocations = <String, double>{};
      var discount = 0.0;
      for (final billId in billIds) {
        final billSnapshot = billSnapshots[billId]!;
        final bill = BillModel.fromMap(
          billSnapshot.data()!,
          documentId: billSnapshot.id,
        );
        final consumed = consumedDiscountByBill[billId] ?? 0.0;
        final remainingDiscount = consumed.isInfinite
            ? 0.0
            : (bill.discount - consumed).clamp(0.0, bill.discount).toDouble();
        if (remainingDiscount > 0) {
          discountAllocations[billId] = remainingDiscount;
          discount += remainingDiscount;
        }
      }

      final refundAmount = (subtotal - discount)
          .clamp(0.0, subtotal)
          .toDouble();
      final sourceBill = BillModel.fromMap(
        billSnapshots[billIds.first]!.data()!,
        documentId: billIds.first,
      );
      final amountAppliedToDue = refundAmount
          .clamp(0.0, sourceBill.amountDue)
          .toDouble();
      final cashRefundAmount = refundAmount - amountAppliedToDue;
      final newAmountDue = sourceBill.amountDue - amountAppliedToDue;
      final paymentStatus = newAmountDue == 0
          ? BillPaymentStatus.paid
          : sourceBill.amountPaid == 0
          ? BillPaymentStatus.due
          : BillPaymentStatus.partial;
      final createdReturn = ReturnModel(
        returnId: returnId,
        originalBillIds: billIds,
        customerPhone: normalizedPhone,
        customerName: customerName,
        items: normalizedItems,
        subtotal: subtotal,
        discount: discount,
        refundAmount: refundAmount,
        amountAppliedToDue: amountAppliedToDue,
        cashRefundAmount: cashRefundAmount,
        createdAt: now,
        createdBy: staffName,
        discountAllocations: discountAllocations,
      );

      for (final entry in quantitiesByProduct.entries) {
        final snapshot = productSnapshots[entry.key]!;
        if (!snapshot.exists) throw _notFound('Product not found.');
        final product = ProductModel.fromMap(
          snapshot.data()!,
          documentId: snapshot.id,
        );
        final newStock = product.stockQuantity + entry.value;
        final logRef = _activityLogs.doc(const Uuid().v4());

        transaction.update(snapshot.reference, {
          'stockQuantity': newStock,
          'updatedAt': Timestamp.fromDate(now),
        });
        transaction.set(
          logRef,
          ActivityLogModel(
            id: logRef.id,
            category: 'inventory',
            action: 'return',
            productId: product.id,
            productName: product.name,
            previousStock: product.stockQuantity,
            newStock: newStock,
            difference: entry.value,
            reason: 'Customer return $returnId',
            notes: 'Original bills: ${billIds.join(', ')}',
            staffId: user.uid,
            staffName: staffName,
            createdAt: now,
          ).toMap(),
        );
      }

      transaction.update(_bills.doc(sourceBill.id), {
        'amountDue': newAmountDue,
        'paymentStatus': paymentStatus.name,
      });
      final auditRef = _activityLogs.doc(const Uuid().v4());
      transaction.set(auditRef, {
        'id': auditRef.id,
        'category': 'billing',
        'action': 'return_payment_adjustment',
        'billId': sourceBill.id,
        'returnId': returnId,
        'productId': '',
        'productName': '',
        'previousStock': 0,
        'newStock': 0,
        'difference': 0,
        'reason': 'Return $returnId applied to bill ${sourceBill.billNumber}',
        'notes':
            'Applied to due: $amountAppliedToDue; Cash refund: $cashRefundAmount',
        'staffId': user.uid,
        'staffName': staffName,
        'createdAt': Timestamp.fromDate(now),
      });

      transaction.set(returnRef, createdReturn.toMap());
      return createdReturn;
    });
  }

  static String _normalizePhone(String phone) => phone.trim();

  static String _sourceKey(String billId, int itemIndex) =>
      '$billId#$itemIndex';

  static FirebaseException _invalid(String message) => FirebaseException(
    plugin: 'cloud_firestore',
    code: 'invalid-argument',
    message: message,
  );

  static FirebaseException _notFound(String message) => FirebaseException(
    plugin: 'cloud_firestore',
    code: 'not-found',
    message: message,
  );
}
