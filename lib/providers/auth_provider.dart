import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    debugPrint('🔧 AuthProvider: Initializing...');
    _initializeAuthListener();
  }

  void _initializeAuthListener() {
    debugPrint('🔧 AuthProvider: Setting up auth listener...');
    _authService.authStateChanges.listen((User? user) async {
      debugPrint('🔧 AuthProvider: Auth state changed - User: ${user?.uid}');
      if (user != null) {
        debugPrint('🔧 AuthProvider: Loading user data for ${user.uid}');
        await _loadUserData(user.uid);
        debugPrint('🔧 AuthProvider: User data loaded successfully');
      } else {
        debugPrint('🔧 AuthProvider: User signed out');
        _currentUser = null;
        notifyListeners();
      }
      _isInitialized = true;
      notifyListeners();
    });
  }

  Future<void> _loadUserData(String uid) async {
    try {
      debugPrint('🔧 AuthProvider: Fetching user document for $uid');
      _currentUser = await _authService.getUserDocument(uid);
      debugPrint(
        '🔧 AuthProvider: User document fetched: ${_currentUser?.email}',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('❌ AuthProvider: Error loading user data: $e');
      _errorMessage = 'Failed to load user data: $e';
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    debugPrint('🔧 AuthProvider: Starting sign up for $email');
    _setLoading(true);
    _clearError();

    try {
      await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      debugPrint('🔧 AuthProvider: Sign up successful');
      return true;
    } catch (e) {
      debugPrint('❌ AuthProvider: Sign up error: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
      debugPrint('🔧 AuthProvider: Sign up process completed');
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    debugPrint('🔧 AuthProvider: Starting sign in for $email');
    _setLoading(true);
    _clearError();

    try {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('🔧 AuthProvider: Sign in successful');
      return true;
    } catch (e) {
      debugPrint('❌ AuthProvider: Sign in error: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
      debugPrint('🔧 AuthProvider: Sign in process completed');
    }
  }

  Future<void> signOut() async {
    debugPrint('🔧 AuthProvider: Starting sign out');
    _setLoading(true);

    try {
      await _authService.signOut();
      debugPrint('🔧 AuthProvider: Sign out successful');
    } catch (e) {
      debugPrint('❌ AuthProvider: Sign out error: $e');
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateUserPreferences(UserPreferences newPreferences) async {
    if (_currentUser == null) return;

    try {
      final updatedUser = _currentUser!.copyWith(preferences: newPreferences);
      await _authService.updateUserDocument(_currentUser!.uid, {
        'preferences': newPreferences.toMap(),
      });
      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update preferences: $e';
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    debugPrint('🔧 AuthProvider: Setting loading to $loading');
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  Future<UserModel?> getUserDocument(String uid) async {
    try {
      return await _authService.getUserDocument(uid);
    } catch (e) {
      debugPrint('❌ AuthProvider: Error getting user document: $e');
      return null;
    }
  }

  Future<void> updateUserDocument(String uid, Map<String, dynamic> data) async {
    try {
      await _authService.updateUserDocument(uid, data);
      await _loadUserData(uid);
    } catch (e) {
      debugPrint('❌ AuthProvider: Error updating user document: $e');
      _errorMessage = 'Failed to update user data: $e';
      notifyListeners();
    }
  }
}
