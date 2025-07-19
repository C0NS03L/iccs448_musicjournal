import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<Map<String, String?>> getUserInfo(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {'displayName': data['displayName'] as String?};
      }

      if (userId == _auth.currentUser?.uid) {
        return {'displayName': _auth.currentUser?.displayName};
      }

      return {'displayName': null};
    } catch (e) {
      print('Error getting user info for $userId: $e');
      return {'displayName': null};
    }
  }

  Future<Map<String, Map<String, String?>>> getMultipleUsersInfo(
    List<String> userIds,
  ) async {
    try {
      final result = <String, Map<String, String?>>{};

      final uniqueUserIds = userIds.toSet().toList();

      for (String userId in uniqueUserIds) {
        final userInfo = await getUserInfo(userId);
        result[userId] = userInfo;
      }

      return result;
    } catch (e) {
      print('Error getting multiple users info: $e');
      return {};
    }
  }

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        // Create user document in Firestore
        await _createUserDocument(user, displayName);
      }

      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last active
      if (result.user != null) {
        await _updateLastActive(result.user!.uid);
      }

      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Get user document from Firestore
  Future<UserModel?> getUserDocument(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, uid);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user document: $e');
    }
  }

  // Update user document
  Future<void> updateUserDocument(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      throw Exception('Failed to update user document: $e');
    }
  }

  // Private helper methods
  Future<void> _createUserDocument(User user, String? displayName) async {
    final userModel = UserModel(
      uid: user.uid,
      email: user.email!,
      displayName: displayName,
      preferences: UserPreferences(),
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
    );

    await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
  }

  Future<void> _updateLastActive(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'lastActive': DateTime.now().toIso8601String(),
    });
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }
}
