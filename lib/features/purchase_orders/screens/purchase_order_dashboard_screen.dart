import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';

class PurchaseOrderDashboardScreen extends StatelessWidget {
  const PurchaseOrderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Purchase Orders'), centerTitle: true),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.15,
        children: [
          _DashboardCard(
            title: 'All Orders',
            icon: Icons.list_alt_outlined,
            color: Colors.orange,
            onTap: () => context.push(AppRoutes.purchaseOrderList),
          ),
          _DashboardCard(
            title: 'Create Order',
            icon: Icons.add_shopping_cart_outlined,
            color: Colors.teal,
            onTap: () => context.push(AppRoutes.purchaseOrderAdd),
          ),
          _DashboardCard(
            title: 'Pending Receipts',
            icon: Icons.local_shipping_outlined,
            color: Colors.indigo,
            onTap: () => context.push(AppRoutes.purchaseOrderList),
          ),
          _DashboardCard(
            title: 'Completed',
            icon: Icons.verified_outlined,
            color: Colors.green,
            onTap: () => context.push(AppRoutes.purchaseOrderList),
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
