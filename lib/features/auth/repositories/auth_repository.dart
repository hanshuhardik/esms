// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// import '../../../shared/models/user_model.dart';
// import '../services/auth_service.dart';
// import '../../../core/utils/result.dart';

// class AuthRepository {
//   AuthRepository._();

//   static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   static User? get currentUser => AuthService.currentUser;

//   static Future<Result<UserModel>> login({
//     required String email,
//     required String password,
//   }) async {
//     try {
//       final credential = await AuthService.signIn(
//         email: email,
//         password: password,
//       );

//       final uid = credential.user!.uid;

//       final doc = await _firestore.collection('users').doc(uid).get();

//       if (!doc.exists) {
//         return Result.failure('User profile not found.');
//       }

//       return Result.success(UserModel.fromMap(doc.data()!, documentId: doc.id));
//     } on FirebaseAuthException catch (e) {
//       return Result.failure(_friendlyAuthError(e.code));
//     } catch (e) {
//       return Result.failure(
//         'Unable to sign in. Check your connection and try again.',
//       );
//     }
//   }

//   static Future<Result<UserModel>> currentProfile() async {
//     final user = AuthService.currentUser;
//     if (user == null) return Result.failure('No authenticated user.');

//     try {
//       final doc = await _firestore.collection('users').doc(user.uid).get();
//       if (!doc.exists) return Result.failure('User profile not found.');

//       final profile = UserModel.fromMap(doc.data()!, documentId: doc.id);
//       if (!profile.isActive) return Result.failure('This account is inactive.');

//       return Result.success(profile);
//     } on FirebaseException catch (e) {
//       return Result.failure(
//         e.code == 'permission-denied'
//             ? 'You do not have permission to access this account.'
//             : 'Unable to load your profile. Check your connection and try again.',
//       );
//     } catch (_) {
//       return Result.failure('Unable to load your profile. Try again.');
//     }
//   }

//   static Future<Result<void>> sendPasswordReset(String email) async {
//     try {
//       await AuthService.sendPasswordResetEmail(email);
//       return Result.success();
//     } on FirebaseAuthException catch (e) {
//       return Result.failure(_friendlyAuthError(e.code));
//     } catch (_) {
//       return Result.failure('Unable to send the reset email. Try again.');
//     }
//   }

//   static Future<void> logout() async {
//     await AuthService.signOut();
//   }

//   static String _friendlyAuthError(String code) {
//     return switch (code) {
//       'invalid-credential' ||
//       'wrong-password' ||
//       'user-not-found' => 'Email or password is incorrect.',
//       'user-disabled' => 'This account has been disabled.',
//       'invalid-email' => 'Enter a valid email address.',
//       'too-many-requests' => 'Too many attempts. Try again later.',
//       'network-request-failed' =>
//         'Network error. Check your connection and try again.',
//       'email-already-in-use' => 'That email address is already in use.',
//       _ => 'Authentication failed. Please try again.',
//     };
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/utils/result.dart';
import '../../../shared/models/user_model.dart';
import '../services/auth_service.dart';

class AuthRepository {
  AuthRepository._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static User? get currentUser => AuthService.currentUser;

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

      return Result.success(UserModel.fromMap(doc.data()!, documentId: doc.id));
    } on FirebaseAuthException catch (e) {
      return Result.failure(_friendlyAuthError(e.code));
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return Result.failure(
          'You do not have permission to access your account.',
        );
      }

      return Result.failure('Firebase error: ${e.code}');
    } catch (e) {
      return Result.failure(
        'Unable to sign in. Check your connection and try again.',
      );
    }
  }

  static Future<Result<UserModel>> currentProfile() async {
    final user = AuthService.currentUser;

    if (user == null) {
      return Result.failure('No authenticated user.');
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        return Result.failure('User profile not found.');
      }

      final profile = UserModel.fromMap(doc.data()!, documentId: doc.id);

      if (!profile.isActive) {
        return Result.failure('This account is inactive.');
      }

      return Result.success(profile);
    } on FirebaseException catch (e) {
      return Result.failure(
        e.code == 'permission-denied'
            ? 'You do not have permission to access this account.'
            : 'Unable to load your profile. Check your connection and try again.',
      );
    } catch (_) {
      return Result.failure('Unable to load your profile. Try again.');
    }
  }

  static Future<Result<void>> sendPasswordReset(String email) async {
    try {
      await AuthService.sendPasswordResetEmail(email);
      return Result.success();
    } on FirebaseAuthException catch (e) {
      return Result.failure(_friendlyAuthError(e.code));
    } catch (_) {
      return Result.failure('Unable to send the reset email. Try again.');
    }
  }

  static Future<void> logout() async {
    await AuthService.signOut();
  }

  static String _friendlyAuthError(String code) {
    return switch (code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'Email or password is incorrect.',
      'user-disabled' => 'This account has been disabled.',
      'invalid-email' => 'Enter a valid email address.',
      'too-many-requests' => 'Too many attempts. Try again later.',
      'network-request-failed' =>
        'Network error. Check your connection and try again.',
      'email-already-in-use' => 'That email address is already in use.',
      _ => 'Authentication failed. Please try again.',
    };
  }
}
