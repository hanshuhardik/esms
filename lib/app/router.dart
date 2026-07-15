import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/setup_screen.dart';
import '../features/auth/screens/splash_screen.dart';

import '../features/dashboard/screens/dashboard_screen.dart';

import '../features/master/master_config.dart';
import '../features/master/screens/master_dashboard_screen.dart';
import '../features/master/screens/master_list_screen.dart';

import '../features/products/screens/add_product_screen.dart';
import '../features/products/screens/edit_product_screen.dart';
import '../features/products/screens/product_details_screen.dart';
import '../features/products/screens/product_list_screen.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      GoRoute(
        path: AppRoutes.setup,
        builder: (context, state) => const SetupScreen(),
      ),

      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),

      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),

      GoRoute(
        path: AppRoutes.products,
        builder: (context, state) => const ProductListScreen(),
      ),

      GoRoute(
        path: AppRoutes.productAdd,
        builder: (context, state) => const AddProductScreen(),
      ),

      GoRoute(
        path: AppRoutes.productDetailsPath,
        builder: (context, state) {
          final productId = state.pathParameters['productId']!;

          return ProductDetailsScreen(productId: productId);
        },
      ),

      GoRoute(
        path: AppRoutes.productEditPath,
        builder: (context, state) {
          final productId = state.pathParameters['productId']!;

          return EditProductScreen(productId: productId);
        },
      ),

      GoRoute(
        path: AppRoutes.masterDashboard,
        builder: (context, state) => const MasterDashboardScreen(),
      ),

      GoRoute(
        path: AppRoutes.masterList,
        builder: (context, state) {
          final config = state.extra as MasterConfig;

          return MasterListScreen(config: config);
        },
      ),
    ],
  );
}
