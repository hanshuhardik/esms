import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/models/shop_model.dart';

class ShopService {
  ShopService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const _collection = 'shops';
  static const _document = 'default';

  static Future<bool> shopExists() async {
    final doc = await _firestore.collection(_collection).doc(_document).get();

    return doc.exists;
  }

  static Future<void> createShop(ShopModel shop) async {
    await _firestore.collection(_collection).doc(_document).set(shop.toMap());
  }

  static Future<ShopModel?> getShop() async {
    final doc = await _firestore.collection(_collection).doc(_document).get();

    if (!doc.exists) return null;

    return ShopModel.fromMap(doc.data()!);
  }
}
