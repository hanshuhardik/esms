import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../../shared/models/user_model.dart';

class StaffService {
  StaffService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestoreCollections.users);

  /// Get a single user by UID.
  static Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _users.doc(uid).get();
      if (!doc.exists) {
        return null;
      }
      return UserModel.fromMap(doc.data()!, documentId: doc.id);
    } catch (e) {
      rethrow;
    }
  }

  /// Watch all users in real-time.
  static Stream<List<UserModel>> watchAllUsers() {
    return _users
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data(), documentId: doc.id))
              .toList(),
        );
  }

  /// Get all users (one-time fetch).
  static Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _users.orderBy('name').get();
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), documentId: doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new user in Firestore.
  ///
  /// Note: This only stores user profile data. Authentication setup
  /// (Firebase Auth account creation) must be done separately via Cloud Functions
  /// or backend, as client-side Firebase Auth cannot securely create arbitrary users.
  static Future<UserModel> createUser({
    required String uid,
    required String name,
    required String email,
    required String phone,
    required UserRole role,
    bool isActive = true,
  }) async {
    try {
      final now = DateTime.now();
      final user = UserModel(
        uid: uid,
        name: name,
        email: email,
        phone: phone,
        role: role,
        isActive: isActive,
        createdAt: now,
        updatedAt: now,
      );

      await _users.doc(uid).set(user.toMap());
      return user;
    } catch (e) {
      rethrow;
    }
  }

  /// Update user details (name, phone, role, active status).
  static Future<UserModel> updateUser({
    required String uid,
    String? name,
    String? phone,
    UserRole? role,
    bool? isActive,
  }) async {
    try {
      final doc = await _users.doc(uid).get();
      if (!doc.exists) {
        throw Exception('User not found');
      }

      final currentUser = UserModel.fromMap(doc.data()!, documentId: doc.id);
      final now = DateTime.now();

      final updated = currentUser.copyWith(
        name: name,
        phone: phone,
        role: role,
        isActive: isActive,
        updatedAt: now,
      );

      await _users.doc(uid).update({
        'name': updated.name,
        'phone': updated.phone,
        'role': updated.role.name,
        'isActive': updated.isActive,
        'updatedAt': Timestamp.fromDate(now),
      });

      return updated;
    } catch (e) {
      rethrow;
    }
  }

  /// Soft-deactivate a user instead of hard deleting.
  static Future<void> deactivateUser(String uid) async {
    try {
      final now = DateTime.now();
      await _users.doc(uid).update({
        'isActive': false,
        'updatedAt': Timestamp.fromDate(now),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Reactivate a deactivated user.
  static Future<void> activateUser(String uid) async {
    try {
      final now = DateTime.now();
      await _users.doc(uid).update({
        'isActive': true,
        'updatedAt': Timestamp.fromDate(now),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Hard delete a user (use with caution; prefer deactivation).
  /// In practice, this should only be called for testing or cleanup,
  /// never for users with historical billing/activity records.
  static Future<void> deleteUser(String uid) async {
    try {
      await _users.doc(uid).delete();
    } catch (e) {
      rethrow;
    }
  }
}
