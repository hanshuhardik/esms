import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/shop_service.dart';
import '../../../core/utils/result.dart';
import '../../../shared/models/shop_model.dart';
import '../../../shared/models/user_model.dart';
import '../../staff/models/authorization.dart';
import '../../staff/models/permission.dart';
import '../models/settings_validator.dart';

class SettingsRepository {
  SettingsRepository._();

  static Future<Result<ShopModel?>> getSettings() async {
    try {
      return Result.success(await ShopService.getShop());
    } on FirebaseException catch (error) {
      return Result.failure(error.message ?? 'Unable to load shop settings.');
    } catch (error) {
      return Result.failure(error.toString());
    }
  }

  static Future<Result<ShopModel>> updateSettings({
    required ShopModel settings,
    required UserModel currentUser,
  }) async {
    if (!Authorization.can(currentUser, Permission.manageSettings)) {
      return Result.failure('You are not authorized to update shop settings.');
    }

    final validationError = SettingsValidator.validateShop(settings);
    if (validationError != null) {
      return Result.failure(validationError);
    }

    try {
      return Result.success(await ShopService.updateShop(settings));
    } on FirebaseException catch (error) {
      return Result.failure(error.message ?? 'Unable to save shop settings.');
    } catch (error) {
      return Result.failure(error.toString());
    }
  }
}
