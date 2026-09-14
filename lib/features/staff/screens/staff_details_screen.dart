import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/models/user_model.dart';
import '../models/role_definition.dart';
import '../providers/staff_provider.dart';

class StaffDetailsScreen extends ConsumerWidget {
  final String staffUid;

  const StaffDetailsScreen({required this.staffUid, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffMemberProvider(staffUid));

    return Scaffold(
      appBar: AppBar(title: const Text('Staff Details'), centerTitle: true),
      floatingActionButton: staffAsync.maybeWhen(
        data: (staff) => staff != null
            ? FloatingActionButton(
                onPressed: () => context.push(AppRoutes.staffEdit(staff.uid)),
                child: const Icon(Icons.edit),
              )
            : null,
        orElse: () => null,
      ),
      body: staffAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(staffMemberProvider(staffUid)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (staff) => staff == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.person_off_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text('Staff member not found'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Profile Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: Colors.blue,
                              child: Text(
                                staff.name.isNotEmpty
                                    ? staff.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Name
                            Text(
                              staff.name,
                              style: Theme.of(context).textTheme.headlineSmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),

                            // Role Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                RoleDefinition.forRole(staff.role).displayName,
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Status
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: staff.isActive
                                    ? Colors.green.withValues(alpha: 0.2)
                                    : Colors.red.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                staff.isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  color: staff.isActive
                                      ? Colors.green[700]
                                      : Colors.red[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Details Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _DetailRow(
                              label: 'Email',
                              value: staff.email,
                              icon: Icons.email_outlined,
                            ),
                            const Divider(),
                            _DetailRow(
                              label: 'Phone',
                              value: staff.phone,
                              icon: Icons.phone_outlined,
                            ),
                            const Divider(),
                            _DetailRow(
                              label: 'Role',
                              value: RoleDefinition.forRole(
                                staff.role,
                              ).displayName,
                              icon: Icons.badge_outlined,
                            ),
                            const Divider(),
                            _DetailRow(
                              label: 'Created',
                              value: _formatDate(staff.createdAt),
                              icon: Icons.calendar_today_outlined,
                            ),
                            const Divider(),
                            _DetailRow(
                              label: 'Updated',
                              value: _formatDate(staff.updatedAt),
                              icon: Icons.update_outlined,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Permissions Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Permissions',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            _PermissionsList(staff: staff),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Role Description
                    Card(
                      color: Colors.blue.withValues(alpha: 0.05),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Role Description',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              RoleDefinition.forRole(staff.role).description,
                              style: TextStyle(
                                color: Colors.grey[700],
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons (if authorized)
                    _ActionButtons(staff: staff),
                  ],
                ),
              ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PermissionsList extends StatelessWidget {
  final UserModel staff;

  const _PermissionsList({required this.staff});

  @override
  Widget build(BuildContext context) {
    final roleDef = RoleDefinition.forRole(staff.role);
    final permissions = roleDef.permissions.toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: permissions
          .map(
            (perm) => Chip(
              label: Text(
                _permissionLabel(perm),
                style: const TextStyle(fontSize: 12),
              ),
              avatar: const Icon(Icons.check_circle, size: 18),
            ),
          )
          .toList(),
    );
  }

  String _permissionLabel(dynamic permission) {
    return permission
        .toString()
        .split('.')
        .last
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
        .trim();
  }
}

class _ActionButtons extends ConsumerWidget {
  final UserModel staff;

  const _ActionButtons({required this.staff});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For now, don't show action buttons in details
    // Actions are in the edit screen
    return const SizedBox.shrink();
  }
}
