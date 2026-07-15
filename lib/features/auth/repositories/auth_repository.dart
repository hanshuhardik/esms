import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../shared/models/user_model.dart';
import '../services/auth_service.dart';
import '../../../core/utils/result.dart';

class AuthRepository {
  AuthRepository._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<Result<UserModel>> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await AuthService.signIn(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        return Result.failure('User profile not found.');
      }

      return Result.success(UserModel.fromMap(doc.data()!));
    } on FirebaseAuthException catch (e) {
      return Result.failure(e.message ?? 'Authentication failed.');
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  static Future<void> logout() async {
    await AuthService.signOut();
  }
}
