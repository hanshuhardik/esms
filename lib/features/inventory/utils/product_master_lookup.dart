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
