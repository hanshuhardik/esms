import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/setup_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/repositories/auth_repository.dart';

import '../features/dashboard/screens/dashboard_screen.dart';

import '../features/master/master_config.dart';
import '../features/master/screens/master_dashboard_screen.dart';
import '../features/master/screens/master_list_screen.dart';

import '../features/inventory/models/inventory_enums.dart';
import '../features/inventory/screens/inventory_dashboard_screen.dart';
import '../features/inventory/screens/inventory_list_screen.dart';
import '../features/inventory/screens/inventory_product_details_screen.dart';
import '../features/inventory/screens/stock_adjustment_screen.dart';
import '../features/inventory/screens/stock_history_screen.dart';

import '../features/billing/screens/bill_details_screen.dart';
import '../features/billing/screens/edit_bill_screen.dart';
import '../features/billing/screens/billing_dashboard_screen.dart';
import '../features/billing/screens/billing_history_screen.dart';
import '../features/billing/screens/billing_pos_screen.dart';

import '../features/reports/screens/reports_dashboard_screen.dart';

import '../features/returns/models/return_model.dart';
import '../features/billing/models/bill_model.dart';
import '../features/returns/screens/return_details_screen.dart';
import '../features/returns/screens/return_form_screen.dart';

import '../features/expenses/screens/expense_details_screen.dart';
import '../features/expenses/screens/expense_form_screen.dart';
import '../features/expenses/screens/expense_list_screen.dart';
import '../features/expenses/screens/expenses_dashboard_screen.dart';

import '../features/purchase_orders/screens/add_purchase_order_screen.dart';
import '../features/purchase_orders/screens/edit_purchase_order_screen.dart';
import '../features/purchase_orders/screens/purchase_order_dashboard_screen.dart';
import '../features/purchase_orders/screens/purchase_order_details_screen.dart';
import '../features/purchase_orders/screens/purchase_order_list_screen.dart';
import '../features/purchase_orders/screens/receive_purchase_order_screen.dart';

import '../features/products/screens/add_product_screen.dart';
import '../features/products/screens/edit_product_screen.dart';
import '../features/products/screens/product_details_screen.dart';
import '../features/products/screens/product_list_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/suppliers/screens/supplier_details_screen.dart';
import '../features/suppliers/screens/supplier_form_screen.dart';
import '../features/suppliers/screens/supplier_list_screen.dart';

import '../features/staff/screens/staff_dashboard_screen.dart';
import '../features/staff/screens/staff_list_screen.dart';
import '../features/staff/screens/staff_details_screen.dart';
import '../features/staff/screens/staff_form_screen.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) async {
      final publicRoutes = {AppRoutes.splash, AppRoutes.login, AppRoutes.setup};
      final isPublic = publicRoutes.contains(state.matchedLocation);

      if (!isPublic) {
        if (AuthRepository.currentUser == null) return AppRoutes.login;

        final profile = await AuthRepository.currentProfile();
        if (profile.isSuccess) return null;
        if (profile.error == 'User profile not found.') {
          return AppRoutes.setup;
        }
        return AppRoutes.login;
      }
      return null;
    },
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
        path: AppRoutes.billing,
        builder: (context, state) => const BillingDashboardScreen(),
      ),

      GoRoute(
        path: AppRoutes.reports,
        builder: (context, state) => const ReportsDashboardScreen(),
      ),

      GoRoute(
        path: AppRoutes.returns,
        builder: (context, state) {
          final bill = state.extra;
          if (bill is BillModel) return ReturnFormScreen(bill: bill);
          return const BillingHistoryScreen();
        },
      ),

      GoRoute(
        path: AppRoutes.returnDetails,
        builder: (context, state) =>
            ReturnDetailsScreen(returnModel: state.extra as ReturnModel),
      ),

      GoRoute(
        path: AppRoutes.billingPos,
        builder: (context, state) => const BillingPosScreen(),
      ),

      GoRoute(
        path: AppRoutes.billingHistory,
        builder: (context, state) => const BillingHistoryScreen(),
      ),

      GoRoute(
        path: AppRoutes.billDetailsPath,
        builder: (context, state) {
          final billId = state.pathParameters['billId']!;

          return BillDetailsScreen(billId: billId);
        },
      ),

      GoRoute(
        path: AppRoutes.billEditPath,
        builder: (context, state) =>
            EditBillScreen(bill: state.extra as BillModel),
      ),

      GoRoute(
        path: AppRoutes.expensesDashboard,
        builder: (context, state) => const ExpensesDashboardScreen(),
      ),

      GoRoute(
        path: AppRoutes.expenseList,
        builder: (context, state) => const ExpenseListScreen(),
      ),

      GoRoute(
        path: AppRoutes.expenseAdd,
        builder: (context, state) => const ExpenseFormScreen(),
      ),

      GoRoute(
        path: AppRoutes.expenseDetailsPath,
        builder: (context, state) {
          final expenseId = state.pathParameters['expenseId']!;

          return ExpenseDetailsScreen(expenseId: expenseId);
        },
      ),

      GoRoute(
        path: AppRoutes.expenseEditPath,
        builder: (context, state) {
          final expenseId = state.pathParameters['expenseId']!;

          return ExpenseFormScreen(expenseId: expenseId);
        },
      ),

      GoRoute(
        path: AppRoutes.purchaseOrders,
        builder: (context, state) => const PurchaseOrderDashboardScreen(),
      ),

      GoRoute(
        path: AppRoutes.purchaseOrderList,
        builder: (context, state) => const PurchaseOrderListScreen(),
      ),

      GoRoute(
        path: AppRoutes.purchaseOrderAdd,
        builder: (context, state) => const AddPurchaseOrderScreen(),
      ),

      GoRoute(
        path: AppRoutes.purchaseOrderDetailsPath,
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;

          return PurchaseOrderDetailsScreen(orderId: orderId);
        },
      ),

      GoRoute(
        path: AppRoutes.purchaseOrderEditPath,
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;

          return EditPurchaseOrderScreen(orderId: orderId);
        },
      ),

      GoRoute(
        path: AppRoutes.purchaseOrderReceivePath,
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;

          return ReceivePurchaseOrderScreen(orderId: orderId);
        },
      ),

      GoRoute(
        path: AppRoutes.inventory,
        builder: (context, state) => const InventoryDashboardScreen(),
      ),

      GoRoute(
        path: AppRoutes.inventoryList,
        builder: (context, state) {
          return const InventoryListScreen(
            title: 'All Inventory',
            filter: InventoryListFilter.all,
          );
        },
      ),

      GoRoute(
        path: AppRoutes.inventoryLowStock,
        builder: (context, state) {
          return const InventoryListScreen(
            title: 'Low Stock',
            filter: InventoryListFilter.lowStock,
          );
        },
      ),

      GoRoute(
        path: AppRoutes.inventoryOutOfStock,
        builder: (context, state) {
          return const InventoryListScreen(
            title: 'Out Of Stock',
            filter: InventoryListFilter.outOfStock,
          );
        },
      ),

      GoRoute(
        path: AppRoutes.inventoryProductDetailsPath,
        builder: (context, state) {
          final productId = state.pathParameters['productId']!;

          return InventoryProductDetailsScreen(productId: productId);
        },
      ),

      GoRoute(
        path: AppRoutes.inventoryStockHistoryPath,
        builder: (context, state) {
          final productId = state.pathParameters['productId']!;

          return StockHistoryScreen(productId: productId);
        },
      ),

      GoRoute(
        path: AppRoutes.inventoryAdjustPath,
        builder: (context, state) {
          final productId = state.pathParameters['productId']!;

          return StockAdjustmentScreen(
            productId: productId,
            title: 'Manual Stock Adjustment',
          );
        },
      ),

      GoRoute(
        path: AppRoutes.inventoryIncreasePath,
        builder: (context, state) {
          final productId = state.pathParameters['productId']!;

          return StockAdjustmentScreen(
            productId: productId,
            title: 'Increase Stock',
            fixedDirection: StockDirection.increase,
          );
        },
      ),

      GoRoute(
        path: AppRoutes.inventoryDecreasePath,
        builder: (context, state) {
          final productId = state.pathParameters['productId']!;

          return StockAdjustmentScreen(
            productId: productId,
            title: 'Decrease Stock',
            fixedDirection: StockDirection.decrease,
          );
        },
      ),

      GoRoute(
        path: AppRoutes.products,
        builder: (context, state) => const ProductListScreen(),
      ),

      GoRoute(
        path: AppRoutes.staff,
        builder: (context, state) => const StaffDashboardScreen(),
      ),

      GoRoute(
        path: AppRoutes.staffList,
        builder: (context, state) => const StaffListScreen(),
      ),

      GoRoute(
        path: AppRoutes.staffAdd,
        builder: (context, state) => const StaffFormScreen(),
      ),

      GoRoute(
        path: AppRoutes.staffDetailsPath,
        builder: (context, state) {
          final staffUid = state.pathParameters['staffUid']!;
          return StaffDetailsScreen(staffUid: staffUid);
        },
      ),

      GoRoute(
        path: AppRoutes.staffEditPath,
        builder: (context, state) {
          final staffUid = state.pathParameters['staffUid']!;
          return StaffFormScreen(staffUid: staffUid);
        },
      ),

      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),

      GoRoute(
        path: AppRoutes.suppliers,
        builder: (context, state) => const SupplierListScreen(),
      ),

      GoRoute(
        path: AppRoutes.supplierAdd,
        builder: (context, state) => const SupplierFormScreen(),
      ),

      GoRoute(
        path: AppRoutes.supplierDetailsPath,
        builder: (context, state) => SupplierDetailsScreen(
          supplierId: state.pathParameters['supplierId']!,
        ),
      ),

      GoRoute(
        path: AppRoutes.supplierEditPath,
        builder: (context, state) =>
            SupplierFormScreen(supplierId: state.pathParameters['supplierId']!),
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
