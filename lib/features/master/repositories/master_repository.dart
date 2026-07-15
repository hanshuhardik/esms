import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/result.dart';
import '../models/master_item_model.dart';
import '../services/master_service.dart';

class MasterRepository {
  MasterRepository._();

  static Future<Result<void>> addItem(
    String collection,
    MasterItemModel item,
  ) async {
    try {
      await MasterService.addItem(collection, item);
      return Result.success();
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Failed to add item.');
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  static Future<Result<void>> updateItem(
    String collection,
    MasterItemModel item,
  ) async {
    try {
      await MasterService.updateItem(collection, item);
      return Result.success();
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Failed to update item.');
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  static Future<Result<void>> deleteItem(String collection, String id) async {
    try {
      await MasterService.deleteItem(collection, id);
      return Result.success();
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Failed to delete item.');
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  static Stream<List<MasterItemModel>> getItems(String collection) {
    return MasterService.getItems(collection);
  }
}
