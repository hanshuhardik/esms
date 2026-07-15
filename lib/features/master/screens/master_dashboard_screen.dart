import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../master_config.dart';

class MasterDashboardScreen extends StatelessWidget {
  const MasterDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Master Data')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: MasterConfigs.all.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final config = MasterConfigs.all[index];

          return _MasterTile(
            config: config,
            onTap: () {
              context.push(AppRoutes.masterList, extra: config);
            },
          );
        },
      ),
    );
  }
}

class _MasterTile extends StatelessWidget {
  final MasterConfig config;
  final VoidCallback onTap;

  const _MasterTile({required this.config, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(config.icon)),
        title: Text(config.title),
        subtitle: Text(config.subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
