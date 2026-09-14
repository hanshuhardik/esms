import 'package:flutter_test/flutter_test.dart';

import 'package:electrical_shop/features/staff/models/authorization.dart';
import 'package:electrical_shop/features/staff/models/permission.dart';
import 'package:electrical_shop/features/staff/models/role_definition.dart';
import 'package:electrical_shop/shared/models/user_model.dart';

void main() {
  group('RoleDefinition Tests', () {
    test('owner role has all permissions', () {
      final ownerRole = RoleDefinition.forRole(UserRole.owner);
      expect(ownerRole.role, UserRole.owner);
      expect(ownerRole.displayName, 'Owner');
      expect(ownerRole.permissions.length, greaterThan(5));
      expect(ownerRole.permissions.contains(Permission.manageStaff), true);
      expect(ownerRole.permissions.contains(Permission.manageSettings), true);
    });

    test('staff role has limited permissions', () {
      final staffRole = RoleDefinition.forRole(UserRole.staff);
      expect(staffRole.role, UserRole.staff);
      expect(staffRole.displayName, 'Staff');
      expect(staffRole.permissions.contains(Permission.createBills), true);
      expect(staffRole.permissions.contains(Permission.manageStaff), false);
    });

    test('electrician role has minimal permissions', () {
      final electricianRole = RoleDefinition.forRole(UserRole.electrician);
      expect(electricianRole.role, UserRole.electrician);
      expect(electricianRole.displayName, 'Electrician');
      expect(
        electricianRole.permissions.contains(Permission.createBills),
        true,
      );
      expect(
        electricianRole.permissions.contains(Permission.manageProducts),
        false,
      );
      expect(
        electricianRole.permissions.contains(Permission.viewReports),
        true,
      );
    });

    test('allRoles returns all three roles', () {
      final roles = RoleDefinition.allRoles();
      expect(roles.length, 3);
      expect(roles.map((r) => r.role).toList(), [
        UserRole.owner,
        UserRole.staff,
        UserRole.electrician,
      ]);
    });
  });

  group('Authorization Tests', () {
    final owner = UserModel(
      uid: 'owner1',
      name: 'Owner',
      email: 'owner@shop.com',
      phone: '1234567890',
      role: UserRole.owner,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final staff = UserModel(
      uid: 'staff1',
      name: 'Staff Member',
      email: 'staff@shop.com',
      phone: '0987654321',
      role: UserRole.staff,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final electrician = UserModel(
      uid: 'elec1',
      name: 'Electrician',
      email: 'elec@shop.com',
      phone: '5555555555',
      role: UserRole.electrician,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final inactiveUser = UserModel(
      uid: 'inactive1',
      name: 'Inactive User',
      email: 'inactive@shop.com',
      phone: '1111111111',
      role: UserRole.staff,
      isActive: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('owner can view dashboard', () {
      expect(Authorization.can(owner, Permission.viewDashboard), true);
    });

    test('owner can manage staff', () {
      expect(Authorization.can(owner, Permission.manageStaff), true);
    });

    test('staff cannot manage staff', () {
      expect(Authorization.can(staff, Permission.manageStaff), false);
    });

    test('staff can create bills', () {
      expect(Authorization.can(staff, Permission.createBills), true);
    });

    test('electrician cannot manage products', () {
      expect(Authorization.can(electrician, Permission.manageProducts), false);
    });

    test('electrician can create bills', () {
      expect(Authorization.can(electrician, Permission.createBills), true);
    });

    test('inactive user cannot access anything', () {
      expect(Authorization.can(inactiveUser, Permission.viewDashboard), false);
      expect(Authorization.can(inactiveUser, Permission.manageStaff), false);
      expect(Authorization.can(inactiveUser, Permission.createBills), false);
    });

    test('owner can manage regular staff', () {
      expect(Authorization.canManageStaff(owner, staff), true);
    });

    test('staff cannot manage anyone', () {
      expect(Authorization.canManageStaff(staff, electrician), false);
    });

    test('staff cannot manage owner', () {
      expect(Authorization.canManageStaff(staff, owner), false);
    });
  });

  group('Owner Protection Tests', () {
    final owner = UserModel(
      uid: 'owner1',
      name: 'Owner',
      email: 'owner@shop.com',
      phone: '1234567890',
      role: UserRole.owner,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final staff = UserModel(
      uid: 'staff1',
      name: 'Staff Member',
      email: 'staff@shop.com',
      phone: '0987654321',
      role: UserRole.staff,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('owner cannot be deleted by owner', () {
      final rules = Authorization.ownerProtectionRules(owner, owner);
      expect(rules.canDelete, false);
      expect(rules.isProtected, true);
    });

    test('owner cannot be deactivated by owner', () {
      final rules = Authorization.ownerProtectionRules(owner, owner);
      expect(rules.canDeactivate, false);
    });

    test('owner cannot have role changed by owner', () {
      final rules = Authorization.ownerProtectionRules(owner, owner);
      expect(rules.canChangeRole, false);
    });

    test('owner can delete regular staff', () {
      final rules = Authorization.ownerProtectionRules(owner, staff);
      expect(rules.canDelete, true);
      expect(rules.isProtected, false);
    });

    test('owner can deactivate regular staff', () {
      final rules = Authorization.ownerProtectionRules(owner, staff);
      expect(rules.canDeactivate, true);
    });

    test('owner protection has reason message', () {
      final rules = Authorization.ownerProtectionRules(owner, owner);
      expect(rules.reason, contains('Owner role'));
      expect(rules.reason, contains('cannot be changed'));
    });
  });

  group('Permission Enum Tests', () {
    test('all permissions are defined', () {
      final permissions = Permission.values;
      expect(permissions.length, greaterThan(0));
      expect(
        permissions.map((p) => p.toString()),
        containsAll([
          'Permission.viewDashboard',
          'Permission.manageProducts',
          'Permission.manageStaff',
        ]),
      );
    });

    test('permission count matches expected', () {
      expect(Permission.values.length, 12);
    });
  });

  group('Staff Validation Tests', () {
    test('staff member data is valid', () {
      final user = UserModel(
        uid: 'uid1',
        name: 'John Doe',
        email: 'john@example.com',
        phone: '1234567890',
        role: UserRole.staff,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(user.uid, isNotEmpty);
      expect(user.name, isNotEmpty);
      expect(user.email, contains('@'));
      expect(user.phone, isNotEmpty);
      expect(user.role, UserRole.staff);
      expect(user.isActive, true);
    });

    test('user copyWith preserves non-modified fields', () {
      final original = UserModel(
        uid: 'uid1',
        name: 'John Doe',
        email: 'john@example.com',
        phone: '1234567890',
        role: UserRole.staff,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = original.copyWith(name: 'Jane Doe', role: UserRole.owner);

      expect(updated.name, 'Jane Doe');
      expect(updated.role, UserRole.owner);
      expect(updated.email, original.email);
      expect(updated.phone, original.phone);
      expect(updated.uid, original.uid);
    });

    test('active/inactive status toggles correctly', () {
      final user = UserModel(
        uid: 'uid1',
        name: 'John Doe',
        email: 'john@example.com',
        phone: '1234567890',
        role: UserRole.staff,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(user.isActive, true);

      final inactive = user.copyWith(isActive: false);
      expect(inactive.isActive, false);

      final active = inactive.copyWith(isActive: true);
      expect(active.isActive, true);
    });
  });

  group('Role Filtering Tests', () {
    final users = [
      UserModel(
        uid: 'u1',
        name: 'Owner One',
        email: 'owner@shop.com',
        phone: '1111111111',
        role: UserRole.owner,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      UserModel(
        uid: 'u2',
        name: 'Staff One',
        email: 'staff1@shop.com',
        phone: '2222222222',
        role: UserRole.staff,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      UserModel(
        uid: 'u3',
        name: 'Staff Two',
        email: 'staff2@shop.com',
        phone: '3333333333',
        role: UserRole.staff,
        isActive: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      UserModel(
        uid: 'u4',
        name: 'Electrician One',
        email: 'elec@shop.com',
        phone: '4444444444',
        role: UserRole.electrician,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    test('can filter by active status', () {
      final active = users.where((u) => u.isActive).toList();
      expect(active.length, 3);
      expect(active.map((u) => u.name).toList(), [
        'Owner One',
        'Staff One',
        'Electrician One',
      ]);
    });

    test('can filter by inactive status', () {
      final inactive = users.where((u) => !u.isActive).toList();
      expect(inactive.length, 1);
      expect(inactive.first.name, 'Staff Two');
    });

    test('can filter by role', () {
      final staffOnly = users.where((u) => u.role == UserRole.staff).toList();
      expect(staffOnly.length, 2);
    });

    test('can search by name', () {
      const query = 'owner';
      final results = users
          .where((u) => u.name.toLowerCase().contains(query))
          .toList();
      expect(results.length, 1);
      expect(results.first.name, 'Owner One');
    });

    test('can search by email', () {
      const query = 'staff';
      final results = users
          .where((u) => u.email.toLowerCase().contains(query))
          .toList();
      expect(results.length, 2);
    });

    test('can search by phone', () {
      const query = '1111111111';
      final results = users.where((u) => u.phone.contains(query)).toList();
      expect(results.length, 1);
      expect(results.first.name, 'Owner One');
    });

    test('combined filters work correctly', () {
      final results = users
          .where((u) => u.isActive && u.role == UserRole.staff)
          .toList();
      expect(results.length, 1);
      expect(results.first.name, 'Staff One');
    });
  });
}
