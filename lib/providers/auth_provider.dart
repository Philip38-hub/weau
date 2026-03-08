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
  ///
  /// On success, callers should navigate to the main route.
  Future<void> signIn({required String idToken}) async {
    _setLoading(true);
    try {
      final token = await _api.authenticate(idToken: idToken);
      // In a real app you'd decode the JWT or call GET /me; here we store a
      // placeholder until the profile screen fills in the full model.
      _user = UserModel(
        id: 'me',
        name: 'Friend Tracker User',
        email: '',
      );
      _error = null;
      debugPrint('AuthProvider: signed in, token length=${token.length}');
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
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
