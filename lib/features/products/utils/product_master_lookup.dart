import '../../master/models/master_item_model.dart';

String resolveMasterName(
  List<MasterItemModel> items,
  String id, {
  String fallback = 'Not set',
}) {
  if (id.isEmpty) {
    return fallback;
  }

  for (final item in items) {
    if (item.id == id) {
      return item.name;
    }
  }

  return fallback;
}

String formatProductDisplayName(String productName, String? brandName) {
  final safeName = productName.trim();
  final safeBrand = (brandName ?? '').trim();

  if (safeName.isEmpty && safeBrand.isEmpty) {
    return 'Product';
  }

  if (safeName.isEmpty) {
    return safeBrand;
  }

  if (safeBrand.isEmpty) {
    return safeName;
  }

  return '$safeName ($safeBrand)';
}

String formatLocationLabel(String? locationName) {
  final safeLocation = (locationName ?? '').trim();
  if (safeLocation.isEmpty) {
    return 'Location: Not set';
  }

  return 'Location: $safeLocation';
}
