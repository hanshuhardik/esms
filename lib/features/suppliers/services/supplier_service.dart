import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/firestore_collections.dart';
import '../models/supplier_model.dart';

class SupplierService {
  SupplierService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _suppliers =>
      _firestore.collection(FirestoreCollections.suppliers);

  static Stream<List<SupplierModel>> watchSuppliers() {
    return _suppliers
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => SupplierModel.fromMap(doc.data(), documentId: doc.id),
              )
              .toList(),
        );
  }

  static Future<SupplierModel?> getSupplier(String id) async {
    final doc = await _suppliers.doc(id).get();

    if (!doc.exists) {
      return null;
    }

    return SupplierModel.fromMap(doc.data()!, documentId: doc.id);
  }

  static Future<SupplierModel> createSupplier(SupplierModel supplier) async {
    final id = supplier.id.trim().isEmpty ? const Uuid().v4() : supplier.id;
    final now = DateTime.now();
    final created = supplier.copyWith(id: id, createdAt: now, updatedAt: now);
    await _suppliers.doc(id).set(created.toMap());
    return created;
  }

  static Future<SupplierModel> updateSupplier(SupplierModel supplier) async {
    final updated = supplier.copyWith(updatedAt: DateTime.now());
    await _suppliers.doc(updated.id).update(updated.toMap());
    return updated;
  }
}
