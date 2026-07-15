import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ESMS Dashboard'), centerTitle: true),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.15,
        children: [
          _DashboardCard(
            title: 'Products',
            icon: Icons.inventory_2_outlined,
            color: Colors.blue,
            onTap: () {
              context.push(AppRoutes.products);
            },
          ),
          _DashboardCard(
            title: 'Billing',
            icon: Icons.receipt_long_outlined,
            color: Colors.green,
            onTap: () {},
          ),
          _DashboardCard(
            title: 'Purchase Orders',
            icon: Icons.shopping_cart_checkout_outlined,
            color: Colors.orange,
            onTap: () {},
          ),
          _DashboardCard(
            title: 'Reports',
            icon: Icons.bar_chart_outlined,
            color: Colors.purple,
            onTap: () {},
          ),
          _DashboardCard(
            title: 'Staff',
            icon: Icons.people_outline,
            color: Colors.teal,
            onTap: () {},
          ),
          _DashboardCard(
            title: 'Master Data',
            icon: Icons.settings_applications_outlined,
            color: Colors.indigo,
            onTap: () {
              context.push(AppRoutes.masterDashboard);
            },
          ),
          _DashboardCard(
            title: 'Settings',
            icon: Icons.settings_outlined,
            color: Colors.grey,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
