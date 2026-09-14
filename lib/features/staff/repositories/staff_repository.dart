import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/result.dart';
import '../../../shared/models/user_model.dart';
import '../services/staff_service.dart';

class StaffRepository {
  StaffRepository._();

  /// Get all staff members.
  static Future<Result<List<UserModel>>> getAllStaff() async {
    try {
      final staff = await StaffService.getAllUsers();
      return Result.success(staff);
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Failed to fetch staff');
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  /// Get a single staff member by UID.
  static Future<Result<UserModel>> getStaffMember(String uid) async {
    try {
      final user = await StaffService.getUser(uid);
      if (user == null) {
        return Result.failure('Staff member not found');
      }
      return Result.success(user);
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Failed to fetch staff member');
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  /// Create a new staff member profile in Firestore.
  static Future<Result<UserModel>> createStaff({
    required String uid,
    required String name,
    required String email,
    required String phone,
    required UserRole role,
  }) async {
    try {
      // Validate inputs
      if (name.trim().isEmpty) {
        return Result.failure('Name is required');
      }
      if (email.trim().isEmpty) {
        return Result.failure('Email is required');
      }
      if (phone.trim().isEmpty) {
        return Result.failure('Phone is required');
      }

      final user = await StaffService.createUser(
        uid: uid,
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        role: role,
        isActive: true,
      );

      return Result.success(user);
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Failed to create staff');
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  /// Update staff member details.
  static Future<Result<UserModel>> updateStaff({
    required String uid,
    String? name,
    String? phone,
    UserRole? role,
    bool? isActive,
  }) async {
    try {
      // Validate non-empty strings
      if (name != null && name.trim().isEmpty) {
        return Result.failure('Name cannot be empty');
      }
      if (phone != null && phone.trim().isEmpty) {
        return Result.failure('Phone cannot be empty');
      }

      final user = await StaffService.updateUser(
        uid: uid,
        name: name?.trim(),
        phone: phone?.trim(),
        role: role,
        isActive: isActive,
      );

      return Result.success(user);
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Failed to update staff');
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  /// Deactivate a staff member.
  static Future<Result<void>> deactivateStaff(String uid) async {
    try {
      await StaffService.deactivateUser(uid);
      return Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Failed to deactivate staff');
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  /// Reactivate a staff member.
  static Future<Result<void>> activateStaff(String uid) async {
    try {
      await StaffService.activateUser(uid);
      return Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Failed to activate staff');
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  /// Delete a staff member (hard delete; use with caution).
  static Future<Result<void>> deleteStaff(String uid) async {
    try {
      await StaffService.deleteUser(uid);
      return Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Failed to delete staff');
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  /// Filter and search staff by multiple criteria.
  static Future<Result<List<UserModel>>> filterStaff({
    required List<UserModel> allStaff,
    String? searchQuery,
    UserRole? roleFilter,
    bool? activeFilter,
  }) async {
    try {
      var filtered = allStaff;

      // Filter by active status
      if (activeFilter != null) {
        filtered = filtered
            .where((user) => user.isActive == activeFilter)
            .toList();
      }

      // Filter by role
      if (roleFilter != null) {
        filtered = filtered.where((user) => user.role == roleFilter).toList();
      }

      // Search by name, email, or phone (case-insensitive)
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final query = searchQuery.toLowerCase();
        filtered = filtered.where((user) {
          return user.name.toLowerCase().contains(query) ||
              user.email.toLowerCase().contains(query) ||
              user.phone.contains(query);
        }).toList();
      }

      return Result.success(filtered);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}
