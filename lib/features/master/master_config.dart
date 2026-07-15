import 'package:flutter/material.dart';

import '../../core/constants/firestore_collections.dart';

class MasterConfig {
  final String title;
  final String singularLabel;
  final String collection;
  final IconData icon;
  final String subtitle;
  final String emptyTitle;
  final String emptySubtitle;
  final String addDialogTitle;
  final String editDialogTitle;
  final String searchHint;

  const MasterConfig({
    required this.title,
    required this.singularLabel,
    required this.collection,
    required this.icon,
    required this.subtitle,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.addDialogTitle,
    required this.editDialogTitle,
    required this.searchHint,
  });
}

class MasterConfigs {
  MasterConfigs._();

  static const brands = MasterConfig(
    title: 'Brands',
    singularLabel: 'Brand',
    collection: FirestoreCollections.brands,
    icon: Icons.sell_outlined,
    subtitle: 'Manage product brands',
    emptyTitle: 'No Brands Found',
    emptySubtitle: 'Tap + to add your first brand.',
    addDialogTitle: 'Add Brand',
    editDialogTitle: 'Edit Brand',
    searchHint: 'Search brands...',
  );

  static const categories = MasterConfig(
    title: 'Categories',
    singularLabel: 'Category',
    collection: FirestoreCollections.categories,
    icon: Icons.category_outlined,
    subtitle: 'Organize products by category',
    emptyTitle: 'No Categories Found',
    emptySubtitle: 'Tap + to add your first category.',
    addDialogTitle: 'Add Category',
    editDialogTitle: 'Edit Category',
    searchHint: 'Search categories...',
  );

  static const locations = MasterConfig(
    title: 'Locations',
    singularLabel: 'Location',
    collection: FirestoreCollections.locations,
    icon: Icons.location_on_outlined,
    subtitle: 'Manage racks and storage locations',
    emptyTitle: 'No Locations Found',
    emptySubtitle: 'Tap + to add your first location.',
    addDialogTitle: 'Add Location',
    editDialogTitle: 'Edit Location',
    searchHint: 'Search locations...',
  );

  static const all = <MasterConfig>[brands, categories, locations];
}
