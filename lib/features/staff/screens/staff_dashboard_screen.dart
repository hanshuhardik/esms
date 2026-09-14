import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../models/role_definition.dart';
import '../providers/staff_provider.dart';

class StaffDashboardScreen extends ConsumerWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffStreamProvider);

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
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(staffStreamProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (staffList) => RefreshIndicator(
          onRefresh: () async {
            final refreshedStaff = ref.refresh(staffStreamProvider.future);
            await refreshedStaff;
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary Cards
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  _SummaryCard(
                    title: 'Total Staff',
                    value: staffList.length.toString(),
                    icon: Icons.people,
                    color: Colors.blue,
                  ),
                  _SummaryCard(
                    title: 'Active',
                    value: staffList.where((s) => s.isActive).length.toString(),
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                  _SummaryCard(
                    title: 'Inactive',
                    value: staffList
                        .where((s) => !s.isActive)
                        .length
                        .toString(),
                    icon: Icons.cancel,
                    color: Colors.orange,
                  ),
                  _SummaryCard(
                    title: 'Owners',
                    value: staffList
                        .where((s) => s.role.name == 'owner')
                        .length
                        .toString(),
                    icon: Icons.admin_panel_settings,
                    color: Colors.purple,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Staff List Header
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Staff Members (${staffList.length})',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton.icon(
                      onPressed: () => context.push(AppRoutes.staffList),
                      icon: const Icon(Icons.view_list),
                      label: const Text('View All'),
                    ),
                  ],
                ),
              ),

              // Recent Staff (top 5)
              if (staffList.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        const Text('No staff members yet'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => context.push(AppRoutes.staffAdd),
                          child: const Text('Add First Staff Member'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...staffList
                    .take(5)
                    .map(
                      (staff) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Text(
                              staff.name.isNotEmpty
                                  ? staff.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(staff.name),
                          subtitle: Text(
                            '${RoleDefinition.forRole(staff.role).displayName} • ${staff.isActive ? 'Active' : 'Inactive'}',
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: Colors.grey[400],
                          ),
                          onTap: () =>
                              context.push(AppRoutes.staffDetails(staff.uid)),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
