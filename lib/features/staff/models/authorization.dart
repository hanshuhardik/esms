import 'package:electrical_shop/shared/models/user_model.dart';

import 'permission.dart';
import 'role_definition.dart';

/// Centralized authorization helper.
class Authorization {
  Authorization._();

  /// Checks if a user has a specific permission.
  static bool can(UserModel user, Permission permission) {
    if (!user.isActive) {
      return false;
    }

    final roleDef = RoleDefinition.forRole(user.role);
    return roleDef.permissions.contains(permission);
  }

  /// Checks if a user can manage a specific staff member.
  ///
  /// Rules:
  /// - Owner can manage anyone except themselves (but can only be deactivated/modified by setup/auth)
  /// - Staff cannot manage anyone
  /// - Electrician cannot manage anyone
  static bool canManageStaff(UserModel currentUser, UserModel targetUser) {
    if (!can(currentUser, Permission.manageStaff)) {
      return false;
    }

    // Owner can manage anyone except they cannot delete/demote themselves through staff UI
    // (Owner protection is handled by ownerProtectionRules)
    return true;
  }

  /// Owner protection rules: prevents accidental removal of the only owner.
  static OwnerProtectionRules ownerProtectionRules(
    UserModel currentUser,
    UserModel targetUser,
  ) {
    return OwnerProtectionRules(
      canDelete:
          currentUser.role == UserRole.owner &&
          targetUser.role != UserRole.owner,
      canDeactivate:
          currentUser.role == UserRole.owner &&
          targetUser.role != UserRole.owner,
      canChangeRole:
          currentUser.role == UserRole.owner &&
          targetUser.role != UserRole.owner,
      reason: targetUser.role == UserRole.owner
          ? 'Owner role cannot be changed, deleted, or deactivated through this interface'
          : null,
    );
  }
}

class OwnerProtectionRules {
  final bool canDelete;
  final bool canDeactivate;
  final bool canChangeRole;
  final String? reason;

  const OwnerProtectionRules({
    required this.canDelete,
    required this.canDeactivate,
    required this.canChangeRole,
    this.reason,
  });

  bool get isProtected => !canDelete || !canDeactivate || !canChangeRole;
}
