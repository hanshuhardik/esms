import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../models/role_definition.dart';
import '../providers/staff_provider.dart';

class StaffListScreen extends ConsumerStatefulWidget {
  const StaffListScreen({super.key});

  @override
  ConsumerState<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends ConsumerState<StaffListScreen> {
  final _searchController = TextEditingController();
  UserRole? _selectedRoleFilter;
  bool? _activeFilter;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref
          .read(staffNotifierProvider.notifier)
          .setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.staffAdd),
        child: const Icon(Icons.person_add),
      ),
      body: staffAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(staffNotifierProvider.notifier).refresh();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (staffList) => staffList.isEmpty
            ? EmptyState(
                icon: Icons.people_outline,
                title: 'No staff members',
                subtitle: 'Add your first staff member to get started.',
              )
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(staffNotifierProvider.notifier).refresh(),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by name, email, or phone...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Filters
                    _FilterBar(
                      selectedRole: _selectedRoleFilter,
                      selectedActive: _activeFilter,
                      onRoleChanged: (role) {
                        setState(() => _selectedRoleFilter = role);
                        ref
                            .read(staffNotifierProvider.notifier)
                            .setRoleFilter(role);
                      },
                      onActiveChanged: (active) {
                        setState(() => _activeFilter = active);
                        ref
                            .read(staffNotifierProvider.notifier)
                            .setActiveFilter(active);
                      },
                      onClear: () {
                        setState(() {
                          _selectedRoleFilter = null;
                          _activeFilter = null;
                          _searchController.clear();
                        });
                        ref.read(staffNotifierProvider.notifier).clearFilters();
                      },
                    ),
                    const SizedBox(height: 16),

                    // Staff List
                    ...staffList.map(
                      (staff) => _StaffListItem(
                        key: ValueKey(staff.uid),
                        staff: staff,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final UserRole? selectedRole;
  final bool? selectedActive;
  final Function(UserRole?) onRoleChanged;
  final Function(bool?) onActiveChanged;
  final VoidCallback onClear;

  const _FilterBar({
    required this.selectedRole,
    required this.selectedActive,
    required this.onRoleChanged,
    required this.onActiveChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasFilters = selectedRole != null || selectedActive != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasFilters)
          Align(
            alignment: Alignment.topRight,
            child: TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filters'),
            ),
          ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Role Filter
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    selectedRole != null
                        ? RoleDefinition.forRole(selectedRole!).displayName
                        : 'All Roles',
                  ),
                  onSelected: (_) {
                    showMenu<UserRole?>(
                      context: context,
                      position: const RelativeRect.fromLTRB(0, 40, 0, 0),
                      items: [
                        const PopupMenuItem(
                          value: null,
                          child: Text('All Roles'),
                        ),
                        ...RoleDefinition.allRoles().map(
                          (roleDef) => PopupMenuItem(
                            value: roleDef.role,
                            child: Text(roleDef.displayName),
                          ),
                        ),
                      ],
                    ).then((value) {
                      if (value != null || true) {
                        onRoleChanged(value);
                      }
                    });
                  },
                ),
              ),

              // Active Status Filter
              FilterChip(
                label: Text(
                  selectedActive == null
                      ? 'All Status'
                      : selectedActive!
                      ? 'Active'
                      : 'Inactive',
                ),
                onSelected: (_) {
                  showMenu<bool?>(
                    context: context,
                    position: const RelativeRect.fromLTRB(0, 40, 0, 0),
                    items: const [
                      PopupMenuItem(value: null, child: Text('All Status')),
                      PopupMenuItem(value: true, child: Text('Active')),
                      PopupMenuItem(value: false, child: Text('Inactive')),
                    ],
                  ).then((value) {
                    if (value != null || true) {
                      onActiveChanged(value);
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StaffListItem extends ConsumerWidget {
  final UserModel staff;

  const _StaffListItem({required this.staff, required Key key})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleDef = RoleDefinition.forRole(staff.role);
    final statusColor = staff.isActive ? Colors.green : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                staff.name,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                staff.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${roleDef.displayName} • ${staff.email}',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
              Text(
                staff.phone,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        onTap: () => context.push(AppRoutes.staffDetails(staff.uid)),
        trailing: IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => context.push(AppRoutes.staffDetails(staff.uid)),
        ),
      ),
    );
  }
}
