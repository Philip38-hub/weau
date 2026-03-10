import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../models/user_model.dart';

/// Manages authentication state: signing in, signing out, and persisting the
/// current [UserModel].
///
/// Pair with Google Sign-In on the UI layer:
/// ```dart
/// final googleUser = await GoogleSignIn().signIn();
/// final auth = await googleUser!.authentication;
/// await context.read<AuthProvider>().signIn(idToken: auth.idToken!);
/// ```
class AuthProvider extends ChangeNotifier {
  final ApiService _api;

  AuthProvider({required ApiService apiService}) : _api = apiService;

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  // ── Getters ────────────────────────────────────────────────────────────────

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Actions ────────────────────────────────────────────────────────────────

  /// Exchanges a Google [idToken] for a backend access_token, then stores it.
  Future<void> signIn({required String idToken}) async {
    _setLoading(true);
    try {
      _user = await _api.authenticate(idToken: idToken);
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Checks if we have a valid token and fetches the user profile.
  Future<void> checkAuth() async {
    final token = await TokenStorage.getToken();
    if (token == null) return;
    
    _setLoading(true);
    try {
      _user = await _api.getMe();
    } catch (e) {
      debugPrint('AuthProvider: auth check failed, clearing token.');
      await signOut();
    } finally {
      _setLoading(false);
    }
  }

  /// Updates user profile settings and refreshes local state.
  Future<void> updateSettings({
    String? name,
    String? avatar,
    bool? trackingEnabled,
    String? visibilityLevel,
    String? precisionLevel,
  }) async {
    try {
      await _api.updateUserSettings(
        name: name,
        avatar: avatar,
        trackingEnabled: trackingEnabled,
        visibilityLevel: visibilityLevel,
        precisionLevel: precisionLevel,
      );
      // Refresh user after update
      _user = await _api.getMe();
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  /// Signs out: clears the token from storage and resets state.
  Future<void> signOut() async {
    await TokenStorage.clearToken();
    _user = null;
    _error = null;
    notifyListeners();
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
