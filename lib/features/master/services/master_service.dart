import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/master_item_model.dart';

class MasterService {
  MasterService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> collection(
    String collectionName,
  ) {
    return _firestore.collection(collectionName);
  }

  static Future<void> addItem(
    String collectionName,
    MasterItemModel item,
  ) async {
    await collection(collectionName).doc(item.id).set(item.toMap());
  }

  static Future<void> updateItem(
    String collectionName,
    MasterItemModel item,
  ) async {
    await collection(collectionName).doc(item.id).update(item.toMap());
  }

  static Future<void> deleteItem(String collectionName, String id) async {
    await collection(collectionName).doc(id).delete();
  }

  static Stream<List<MasterItemModel>> getItems(String collectionName) {
    return collection(collectionName)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    MasterItemModel.fromMap(doc.data(), documentId: doc.id),
              )
              .toList(),
        );
  }
}
