import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/user_model.dart';
import '../repositories/staff_repository.dart';
import '../services/staff_service.dart';

// Stream provider for all staff members (real-time updates)
final staffStreamProvider = StreamProvider<List<UserModel>>((ref) {
  return StaffService.watchAllUsers();
});

// State notifier for filtered/searched staff list
final staffNotifierProvider =
    StateNotifierProvider<StaffNotifier, AsyncValue<List<UserModel>>>(
      (ref) => StaffNotifier(ref),
    );

class StaffNotifier extends StateNotifier<AsyncValue<List<UserModel>>> {
  final Ref ref;

  StaffNotifier(this.ref) : super(const AsyncLoading()) {
    _loadStaff();
  }

  String _searchQuery = '';
  UserRole? _roleFilter;
  bool? _activeFilter;

  Future<void> _loadStaff() async {
    state = const AsyncLoading();
    final result = await StaffRepository.getAllStaff();

    if (result.isSuccess) {
      state = AsyncData(result.data ?? []);
      await _applyFilters();
    } else {
      state = AsyncError(result.error!, StackTrace.current);
    }
  }

  Future<void> _applyFilters() async {
    final currentData = state.maybeWhen(
      data: (data) => data,
      orElse: () => <UserModel>[],
    );

    final result = await StaffRepository.filterStaff(
      allStaff: currentData,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      roleFilter: _roleFilter,
      activeFilter: _activeFilter,
    );

    if (result.isSuccess) {
      state = AsyncData(result.data ?? []);
    } else {
      state = AsyncError(result.error!, StackTrace.current);
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setRoleFilter(UserRole? role) {
    _roleFilter = role;
    _applyFilters();
  }

  void setActiveFilter(bool? active) {
    _activeFilter = active;
    _applyFilters();
  }

  void clearFilters() {
    _searchQuery = '';
    _roleFilter = null;
    _activeFilter = null;
    _loadStaff();
  }

  Future<bool> createStaff({
    required String uid,
    required String name,
    required String email,
    required String phone,
    required UserRole role,
  }) async {
    state = const AsyncLoading();

    final result = await StaffRepository.createStaff(
      uid: uid,
      name: name,
      email: email,
      phone: phone,
      role: role,
    );

    if (result.isSuccess) {
      await _loadStaff();
      return true;
    } else {
      state = AsyncError(result.error!, StackTrace.current);
      return false;
    }
  }

  Future<bool> updateStaff({
    required String uid,
    String? name,
    String? phone,
    UserRole? role,
    bool? isActive,
  }) async {
    state = const AsyncLoading();

    final result = await StaffRepository.updateStaff(
      uid: uid,
      name: name,
      phone: phone,
      role: role,
      isActive: isActive,
    );

    if (result.isSuccess) {
      await _loadStaff();
      return true;
    } else {
      state = AsyncError(result.error!, StackTrace.current);
      return false;
    }
  }

  Future<bool> deactivateStaff(String uid) async {
    final result = await StaffRepository.deactivateStaff(uid);

    if (result.isSuccess) {
      await _loadStaff();
      return true;
    } else {
      state = AsyncError(result.error!, StackTrace.current);
      return false;
    }
  }

  Future<bool> activateStaff(String uid) async {
    final result = await StaffRepository.activateStaff(uid);

    if (result.isSuccess) {
      await _loadStaff();
      return true;
    } else {
      state = AsyncError(result.error!, StackTrace.current);
      return false;
    }
  }

  Future<bool> deleteStaff(String uid) async {
    final result = await StaffRepository.deleteStaff(uid);

    if (result.isSuccess) {
      await _loadStaff();
      return true;
    } else {
      state = AsyncError(result.error!, StackTrace.current);
      return false;
    }
  }

  Future<void> refresh() async {
    await _loadStaff();
  }
}

// Single staff member provider
final staffMemberProvider = FutureProvider.family<UserModel?, String>((
  ref,
  uid,
) async {
  final result = await StaffRepository.getStaffMember(uid);
  return result.isSuccess ? result.data : null;
});
