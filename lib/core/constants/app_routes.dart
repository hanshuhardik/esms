class AppRoutes {
  AppRoutes._();

  // Authentication
  static const splash = '/';
  static const setup = '/setup';
  static const login = '/login';

  // Dashboard
  static const dashboard = '/dashboard';

  // Inventory
  static const inventory = '/inventory';
  static const inventoryList = '/inventory/list';
  static const inventoryLowStock = '/inventory/low-stock';
  static const inventoryOutOfStock = '/inventory/out-of-stock';
  static const inventoryProductDetailsPath = '/inventory/products/:productId';
  static const inventoryStockHistoryPath =
      '/inventory/products/:productId/history';
  static const inventoryAdjustPath = '/inventory/products/:productId/adjust';
  static const inventoryIncreasePath =
      '/inventory/products/:productId/increase';
  static const inventoryDecreasePath =
      '/inventory/products/:productId/decrease';

  static String inventoryProductDetails(String productId) =>
      '/inventory/products/$productId';

  static String inventoryStockHistory(String productId) =>
      '/inventory/products/$productId/history';

  static String inventoryAdjust(String productId) =>
      '/inventory/products/$productId/adjust';

  static String inventoryIncrease(String productId) =>
      '/inventory/products/$productId/increase';

  static String inventoryDecrease(String productId) =>
      '/inventory/products/$productId/decrease';

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

  // Purchase Orders
  static const purchaseOrderList = '/purchase-orders/list';
  static const purchaseOrderAdd = '/purchase-orders/add';
  static const purchaseOrderDetailsPath = '/purchase-orders/:orderId';
  static const purchaseOrderEditPath = '/purchase-orders/:orderId/edit';
  static const purchaseOrderReceivePath = '/purchase-orders/:orderId/receive';

  static String purchaseOrderDetails(String orderId) =>
      '/purchase-orders/$orderId';

  static String purchaseOrderEdit(String orderId) =>
      '/purchase-orders/$orderId/edit';

  static String purchaseOrderReceive(String orderId) =>
      '/purchase-orders/$orderId/receive';

  // Billing
  static const billing = '/billing';
  static const billingPos = '/billing/pos';
  static const billingHistory = '/billing/history';
  static const billDetailsPath = '/billing/:billId';
  static const billEditPath = '/billing/:billId/edit';

  static String billDetails(String billId) => '/billing/$billId';

  static String billEdit(String billId) => '/billing/$billId/edit';

  // Expenses
  static const expensesDashboard = '/expenses';
  static const expenseList = '/expenses/list';
  static const expenseAdd = '/expenses/add';
  static const expenseDetailsPath = '/expenses/:expenseId';
  static const expenseEditPath = '/expenses/:expenseId/edit';

  static String expenseDetails(String expenseId) => '/expenses/$expenseId';

  static String expenseEdit(String expenseId) => '/expenses/$expenseId/edit';

  // Staff
  static const staff = '/staff';
  static const staffList = '/staff/list';
  static const staffAdd = '/staff/add';
  static const staffDetailsPath = '/staff/:staffUid';
  static const staffEditPath = '/staff/:staffUid/edit';

  static String staffDetails(String staffUid) => '/staff/$staffUid';

  static String staffEdit(String staffUid) => '/staff/$staffUid/edit';

  // Suppliers
  static const suppliers = '/suppliers';
  static const supplierAdd = '/suppliers/add';
  static const supplierDetailsPath = '/suppliers/:supplierId';
  static const supplierEditPath = '/suppliers/:supplierId/edit';

  static String supplierDetails(String supplierId) => '/suppliers/$supplierId';

  static String supplierEdit(String supplierId) =>
      '/suppliers/$supplierId/edit';

  // Future Modules
  static const purchaseOrders = '/purchase-orders';
  static const returns = '/returns';
  static const returnDetails = '/returns/details';
  static const reports = '/reports';
  static const settings = '/settings';
}
