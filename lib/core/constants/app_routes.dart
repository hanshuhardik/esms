class AppRoutes {
  AppRoutes._();

  // Authentication
  static const splash = '/';
  static const setup = '/setup';
  static const login = '/login';

  // Dashboard
  static const dashboard = '/dashboard';

  // Master Data
  static const masterDashboard = '/master-dashboard';
  static const masterList = '/master-list';

  // Products
  static const products = '/products';
  static const productAdd = '/products/add';
  static const productDetailsPath = '/products/:productId';
  static const productEditPath = '/products/:productId/edit';

  static String productDetails(String productId) => '/products/$productId';

  static String productEdit(String productId) => '/products/$productId/edit';

  // Future Modules
  static const suppliers = '/suppliers';
  static const purchaseOrders = '/purchase-orders';
  static const billing = '/billing';
  static const inventory = '/inventory';
  static const returns = '/returns';
  static const expenses = '/expenses';
  static const reports = '/reports';
  static const settings = '/settings';
}
