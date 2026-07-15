import 'package:cloud_firestore/cloud_firestore.dart';

class MasterItemModel {
  final String id;
  final String name;
  final DateTime createdAt;

  const MasterItemModel({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory MasterItemModel.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    final rawId = map['id'];
    final rawName = map['name'];
    final rawCreatedAt = map['createdAt'];

    return MasterItemModel(
      id: rawId is String && rawId.isNotEmpty ? rawId : (documentId ?? ''),
      name: rawName?.toString() ?? '',
      createdAt: rawCreatedAt is Timestamp
          ? rawCreatedAt.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'createdAt': Timestamp.fromDate(createdAt)};
  }

  MasterItemModel copyWith({String? id, String? name, DateTime? createdAt}) {
    return MasterItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
