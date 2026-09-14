import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../../core/services/shop_service.dart';
import '../../../features/auth/services/auth_service.dart';
import '../../../shared/models/activity_log_model.dart';
import '../../../shared/models/shop_model.dart';
import '../../products/models/product_model.dart';
import '../models/bill_model.dart';

class BillingService {
  BillingService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _bills =>
      _firestore.collection(FirestoreCollections.bills);

  static CollectionReference<Map<String, dynamic>> get _returns =>
      _firestore.collection(FirestoreCollections.returns);

  static CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection(FirestoreCollections.products);

  static CollectionReference<Map<String, dynamic>> get _activityLogs =>
      _firestore.collection(FirestoreCollections.activityLogs);

  static CollectionReference<Map<String, dynamic>> get _counters =>
      _firestore.collection(FirestoreCollections.counters);

  static Stream<List<BillModel>> watchBills() {
    return _bills
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BillModel.fromMap(doc.data(), documentId: doc.id))
              .toList(),
        );
  }

  static Future<BillModel?> getBill(String billId) async {
    final doc = await _bills.doc(billId).get();

    if (!doc.exists) {
      return null;
    }

    return BillModel.fromMap(doc.data()!, documentId: doc.id);
  }

  static Future<BillModel> collectDuePayment({
    required String billId,
    required double amountReceived,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        message: 'User must be signed in to collect payment.',
      );
    }

    final billRef = _bills.doc(billId);
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(billRef);
      if (!snapshot.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message: 'Bill not found.',
        );
      }

      final bill = BillModel.fromMap(snapshot.data()!, documentId: snapshot.id);
      if (!bill.isCompleted) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message: 'Only completed bills can receive payment.',
        );
      }
      if (amountReceived <= 0 || amountReceived > bill.amountDue) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message:
              'Amount received must be greater than zero and no more than the outstanding due.',
        );
      }

      final amountPaid = bill.amountPaid + amountReceived;
      final amountDue = (bill.total - amountPaid)
          .clamp(0.0, bill.total)
          .toDouble();
      final paymentStatus = amountDue == 0
          ? BillPaymentStatus.paid
          : BillPaymentStatus.partial;
      final now = DateTime.now();
      final auditRef = _activityLogs.doc(const Uuid().v4());

      transaction.update(billRef, {
        'amountPaid': amountPaid,
        'amountDue': amountDue,
        'paymentStatus': paymentStatus.name,
      });
      transaction.set(auditRef, {
        'id': auditRef.id,
        'category': 'billing',
        'action': 'payment_collection',
        'billId': bill.id,
        'productId': '',
        'productName': '',
        'previousStock': 0,
        'newStock': 0,
        'difference': 0,
        'reason': 'Due payment collected for bill ${bill.billNumber}',
        'notes': 'Amount collected: $amountReceived',
        'staffId': user.uid,
        'staffName': user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : (user.email ?? 'Unknown Staff'),
        'createdAt': Timestamp.fromDate(now),
      });

      return bill.copyWith(
        amountPaid: amountPaid,
        amountDue: amountDue,
        paymentStatus: paymentStatus,
      );
    });
  }

  static Future<BillModel> updateBill({
    required String billId,
    required double discount,
    required double amountPaid,
    required BillPaymentStatus paymentStatus,
    String? customerPhone,
    String? takenBy,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        message: 'User must be signed in to edit bills.',
      );
    }

    final billRef = _bills.doc(billId);
    final returnSnapshot = await _returnsForBill(billId);

    return _firestore.runTransaction((transaction) async {
      final billSnapshot = await transaction.get(billRef);
      if (!billSnapshot.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message: 'Bill not found.',
        );
      }

      final bill = BillModel.fromMap(
        billSnapshot.data()!,
        documentId: billSnapshot.id,
      );
      if (!bill.isCompleted) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message: 'Only completed bills can be edited.',
        );
      }
      if (returnSnapshot.docs.isNotEmpty && discount != bill.discount) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message:
              'Discount cannot be changed after a return has been processed for this bill.',
        );
      }
      if (discount < 0 || discount > bill.subtotal) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message: 'Discount must be between zero and the subtotal.',
        );
      }

      final total = BillModel.calculateTotal(
        subtotal: bill.subtotal,
        discount: discount,
      );
      if (amountPaid < 0 || amountPaid > total) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message: 'Amount paid must be between zero and the bill total.',
        );
      }
      if (paymentStatus == BillPaymentStatus.paid && amountPaid != total) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message: 'A paid bill must have the full amount paid.',
        );
      }
      if (paymentStatus == BillPaymentStatus.partial &&
          (amountPaid <= 0 || amountPaid >= total)) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message: 'A partial payment must be between zero and the total.',
        );
      }
      if (paymentStatus == BillPaymentStatus.due && amountPaid != 0) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message: 'A due bill cannot have a paid amount.',
        );
      }

      final amountDue = total - amountPaid;
      final now = DateTime.now();
      final normalizedPhone = _normalizeOptional(customerPhone);
      final changes = <String, dynamic>{
        'discount': discount,
        'total': total,
        'amountPaid': amountPaid,
        'amountDue': amountDue,
        'paymentStatus': paymentStatus.name,
        'customerPhone': normalizedPhone,
        'takenBy': _normalizeTakenBy(takenBy),
      };
      final auditRef = _activityLogs.doc(const Uuid().v4());
      transaction.update(billRef, changes);
      transaction.set(auditRef, {
        'id': auditRef.id,
        'category': 'billing',
        'action': 'bill_edit',
        'billId': bill.id,
        'productId': '',
        'productName': '',
        'previousStock': 0,
        'newStock': 0,
        'difference': 0,
        'reason': 'Bill ${bill.billNumber} edited',
        'notes': 'Changed: ${changes.keys.join(', ')}',
        'staffId': user.uid,
        'staffName': user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : (user.email ?? 'Unknown Staff'),
        'createdAt': Timestamp.fromDate(now),
      });

      return bill.copyWith(
        discount: discount,
        total: total,
        amountPaid: amountPaid,
        amountDue: amountDue,
        paymentStatus: paymentStatus,
        customerPhone: normalizedPhone,
        takenBy: _normalizeTakenBy(takenBy),
      );
    });
  }

  static Future<QuerySnapshot<Map<String, dynamic>>> _returnsForBill(
    String billId,
  ) {
    return _returns
        .where('originalBillIds', arrayContains: billId)
        .limit(1)
        .get();
  }

  static Future<BillModel> createBill({
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
    final shop = await ShopService.getShop();
    final shopPrefix = _resolveBillPrefix(shop);
    final user = AuthService.currentUser;
    final createdBy = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : (user?.email ?? 'Unknown Staff');
    final now = DateTime.now();
    final billRef = _bills.doc(billId);
    final counterRef = _counters.doc('bills');

    final createdBill = await _firestore.runTransaction((transaction) async {
      final existingBillSnapshot = await transaction.get(billRef);

      if (existingBillSnapshot.exists) {
        return BillModel.fromMap(
          existingBillSnapshot.data()!,
          documentId: existingBillSnapshot.id,
        );
      }

      final counterSnapshot = await transaction.get(counterRef);
      final currentSequence = counterSnapshot.exists
          ? _readInt(counterSnapshot.data()?['sequence'])
          : 0;
      final nextSequence = BillModel.nextSequence(currentSequence);
      final billNumber = BillModel.formatBillNumber(shopPrefix, nextSequence);

      final subtotal = BillModel.calculateSubtotal(items);
      final safeDiscount = discount < 0 ? 0.0 : discount;
      final total = BillModel.calculateTotal(
        subtotal: subtotal,
        discount: safeDiscount,
      );
      if (amountPaid < 0 || amountPaid > total) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message: 'Amount paid must be between zero and the bill total.',
        );
      }
      if (paymentStatus == BillPaymentStatus.paid && amountPaid != total) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message: 'A paid bill must have the full amount paid.',
        );
      }
      if (paymentStatus == BillPaymentStatus.partial &&
          (amountPaid <= 0 || amountPaid >= total)) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message: 'A partial payment must be between zero and the total.',
        );
      }
      if (paymentStatus == BillPaymentStatus.due && amountPaid != 0) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message: 'A due bill cannot have a paid amount.',
        );
      }
      final amountDue = total - amountPaid;

      final updatedStocks = <String, int>{};

      for (final item in items) {
        if (item.quantity <= 0) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            message: 'Invalid quantity for ${item.productName}.',
          );
        }

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

        if (product.status != ProductStatus.active) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            message: '${product.name} is inactive and cannot be sold.',
          );
        }

        if (!BillModel.canSellAgainstStock(
          requestedQuantity: item.quantity,
          availableStock: product.stockQuantity,
        )) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            message: 'Insufficient stock for ${product.name}.',
          );
        }

        final newStock = product.stockQuantity - item.quantity;
        updatedStocks[item.productId] = newStock;
      }

      for (final entry in updatedStocks.entries) {
        final productRef = _products.doc(entry.key);
        final currentSnapshot = await transaction.get(productRef);
        final product = ProductModel.fromMap(
          currentSnapshot.data()!,
          documentId: currentSnapshot.id,
        );
        final quantitySold = items
            .firstWhere((item) => item.productId == entry.key)
            .quantity;
        final newStock = entry.value;

        transaction.update(productRef, {
          'stockQuantity': newStock,
          'updatedAt': Timestamp.fromDate(now),
        });

        final logRef = _activityLogs.doc(const Uuid().v4());
        transaction.set(
          logRef,
          ActivityLogModel(
            id: logRef.id,
            category: 'billing',
            action: 'sale',
            productId: product.id,
            productName: product.name,
            previousStock: product.stockQuantity,
            newStock: newStock,
            difference: -quantitySold,
            reason: 'Bill $billNumber',
            notes: customerPhone?.trim().isNotEmpty == true
                ? 'Customer: ${customerPhone!.trim()}'
                : null,
            staffId: user?.uid ?? 'unknown',
            staffName: createdBy,
            createdAt: now,
          ).toMap(),
        );
      }

      final bill = BillModel(
        id: billId,
        billNumber: billNumber,
        billSequence: nextSequence,
        items: items,
        subtotal: subtotal,
        discount: safeDiscount,
        total: total,
        paymentMethod: paymentMethod,
        amountPaid: amountPaid,
        amountDue: amountDue,
        paymentStatus: paymentStatus,
        customerName: _normalizeOptional(customerName),
        customerPhone: _normalizeOptional(customerPhone),
        takenBy: _normalizeTakenBy(takenBy),
        createdBy: createdBy,
        createdAt: now,
        status: BillStatus.completed,
      );

      transaction.set(billRef, bill.toMap());
      transaction.set(counterRef, {
        'id': 'bills',
        'sequence': nextSequence,
        'updatedAt': Timestamp.fromDate(now),
      });

      return bill;
    });

    return createdBill;
  }

  static String _resolveBillPrefix(ShopModel? shop) {
    final prefix = shop?.billPrefix.trim() ?? '';
    return prefix.isEmpty ? 'BILL' : prefix;
  }

  static String? _normalizeOptional(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static String _normalizeTakenBy(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? 'Walk-in Customer' : text;
  }

  static int _readInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
