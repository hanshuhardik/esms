// import 'package:flutter_riverpod/flutter_riverpod.dart';

// import '../../../shared/models/user_model.dart';
// import '../repositories/auth_repository.dart';

// final authProvider =
//     StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>(
//       (ref) => AuthNotifier(),
//     );

// class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
//   AuthNotifier() : super(const AsyncData(null));

//   Future<bool> login({required String email, required String password}) async {
//     state = const AsyncLoading();

//     final result = await AuthRepository.login(email: email, password: password);

//     if (result.isSuccess) {
//       state = AsyncData(result.data);
//       return true;
//     }

//     state = AsyncError(result.error!, StackTrace.current);

//     return false;
//   }

//   Future<void> loadCurrentProfile() async {
//     state = const AsyncLoading();
//     final result = await AuthRepository.currentProfile();
//     state = result.isSuccess
//         ? AsyncData(result.data)
//         : AsyncError(result.error!, StackTrace.current);
//   }

//   Future<void> logout() async {
//     await AuthRepository.logout();

//     state = const AsyncData(null);
//   }

//   Future<void> sendPasswordReset(String email) {
//     return AuthRepository.sendPasswordReset(email).then((result) {
//       if (result.isFailure) throw Exception(result.error);
//     });
//   }
// }

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/user_model.dart';
import '../repositories/auth_repository.dart';

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>(
      (ref) => AuthNotifier(),
    );

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  AuthNotifier() : super(const AsyncData(null));

  Future<bool> login({required String email, required String password}) async {
    state = const AsyncLoading();

    final result = await AuthRepository.login(email: email, password: password);

    if (result.isSuccess) {
      state = AsyncData(result.data);
      return true;
    }

    state = AsyncError(result.error!, StackTrace.current);

    return false;
  }

  Future<bool> loadCurrentProfile() async {
    state = const AsyncLoading();

    final result = await AuthRepository.currentProfile();

    if (result.isSuccess) {
      state = AsyncData(result.data);
      return true;
    }

    state = AsyncError(result.error!, StackTrace.current);

    return false;
  }

  Future<void> logout() async {
    await AuthRepository.logout();
    state = const AsyncData(null);
  }

  Future<void> sendPasswordReset(String email) {
    return AuthRepository.sendPasswordReset(email).then((result) {
      if (result.isFailure) {
        throw Exception(result.error);
      }
    });
  }
}
