import 'package:electrical_shop/shared/models/user_model.dart';

import 'permission.dart';

/// Defines which permissions are granted for each role.
class RoleDefinition {
  final UserRole role;
  final String displayName;
  final String description;
  final Set<Permission> permissions;

  const RoleDefinition({
    required this.role,
    required this.displayName,
    required this.description,
    required this.permissions,
  });

  static const RoleDefinition owner = RoleDefinition(
    role: UserRole.owner,
    displayName: 'Owner',
    description: 'Full access to all features',
    permissions: {
      Permission.viewDashboard,
      Permission.manageProducts,
      Permission.manageInventory,
      Permission.manageMasterData,
      Permission.manageSuppliers,
      Permission.managePurchaseOrders,
      Permission.createBills,
      Permission.viewBills,
      Permission.manageExpenses,
      Permission.processReturns,
      Permission.viewReports,
      Permission.manageStaff,
      Permission.manageSettings,
    },
  );

  static const RoleDefinition staff = RoleDefinition(
    role: UserRole.staff,
    displayName: 'Staff',
    description: 'Can manage most operations',
    permissions: {
      Permission.viewDashboard,
      Permission.manageProducts,
      Permission.manageInventory,
      Permission.manageSuppliers,
      Permission.managePurchaseOrders,
      Permission.createBills,
      Permission.viewBills,
      Permission.manageExpenses,
      Permission.processReturns,
      Permission.viewReports,
    },
  );

  static const RoleDefinition electrician = RoleDefinition(
    role: UserRole.electrician,
    displayName: 'Electrician',
    description: 'Can create bills and view reports',
    permissions: {
      Permission.viewDashboard,
      Permission.createBills,
      Permission.viewBills,
      Permission.viewReports,
    },
  );

  /// Returns the role definition for a given role.
  static RoleDefinition forRole(UserRole role) {
    return switch (role) {
      UserRole.owner => owner,
      UserRole.staff => staff,
      UserRole.electrician => electrician,
    };
  }

  /// Returns all available role definitions.
  static List<RoleDefinition> allRoles() => [owner, staff, electrician];
}
