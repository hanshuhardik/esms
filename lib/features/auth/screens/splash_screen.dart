// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// import '../../../core/constants/app_routes.dart';
// import '../repositories/auth_repository.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> {
//   @override
//   void initState() {
//     super.initState();
//     _initialize();
//   }

//   Future<void> _initialize() async {
//     final user = AuthRepository.currentUser;

//     if (user == null) {
//       if (mounted) context.go(AppRoutes.login);
//       return;
//     }

//     final result = await AuthRepository.currentProfile();

//     if (!mounted) return;

//     if (result.isSuccess) {
//       context.go(AppRoutes.dashboard);
//     } else if (result.error == 'User profile not found.') {
//       context.go(AppRoutes.setup);
//     } else {
//       await AuthRepository.logout();
//       if (mounted) {
//         context.go(AppRoutes.login);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(body: Center(child: CircularProgressIndicator()));
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../providers/auth_provider.dart';
import '../repositories/auth_repository.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    final user = AuthRepository.currentUser;

    if (user == null) {
      if (!mounted) return;
      context.go(AppRoutes.login);
      return;
    }

    // Load the profile through the Riverpod auth provider.
    final success = await ref.read(authProvider.notifier).loadCurrentProfile();

    if (!mounted) return;

    if (success) {
      context.go(AppRoutes.dashboard);
      return;
    }

    final authState = ref.read(authProvider);

    final error = authState.hasError ? authState.error.toString() : '';

    if (error == 'User profile not found.') {
      context.go(AppRoutes.setup);
      return;
    }

    await ref.read(authProvider.notifier).logout();

    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
