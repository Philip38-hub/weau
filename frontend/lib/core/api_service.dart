import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/user_model.dart';

/// Thin persistence wrapper around [SharedPreferences] for the JWT token.
class TokenStorage {
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
  }
}

// ── Custom exception ──────────────────────────────────────────────────────────

/// Thrown when the backend returns a non-2xx status code.
class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

// ── Service ───────────────────────────────────────────────────────────────────

/// Centralised HTTP client for ALL Friend Tracker backend endpoints.
///
/// Usage:
/// ```dart
/// final api = ApiService();
/// final token = await api.authenticate(idToken: googleIdToken);
/// ```
///
/// Every protected method reads the stored token automatically via
/// [_authHeaders]. Tokens are written by [authenticate] and erased by
/// [TokenStorage.clearToken].
class ApiService {
  final String _base;
  final http.Client _client;

  ApiService({String? baseUrl, http.Client? client})
      : _base = baseUrl ?? AppConstants.baseUrl,
        _client = client ?? http.Client();

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<Map<String, String>> _authHeaders() async {
    final token = await TokenStorage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    String message;
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      message = body['message'] as String? ?? response.reasonPhrase ?? 'Error';
    } catch (_) {
      message = response.reasonPhrase ?? 'Unknown error';
    }
    throw ApiException(response.statusCode, message);
  }

  List<dynamic> _decodeList(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return [];
      return jsonDecode(response.body) as List<dynamic>;
    }
    String message;
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      message = body['message'] as String? ?? response.reasonPhrase ?? 'Error';
    } catch (_) {
      message = response.reasonPhrase ?? 'Unknown error';
    }
    throw ApiException(response.statusCode, message);
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  /// POST /auth
  ///
  /// Exchanges a Google [idToken] for a backend [accessToken].
  /// Persists the token via [TokenStorage] automatically.
  ///
  /// Returns the [UserModel].
  Future<UserModel> authenticate({required String idToken}) async {
    final response = await _client.post(
      Uri.parse('$_base/auth'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_token': idToken}),
    );
    final data = _decode(response);
    final token = data['access_token'] as String;
    await TokenStorage.saveToken(token);
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  // ── User ──────────────────────────────────────────────────────────────────

  /// GET /users/me
  Future<UserModel> getMe() async {
    final response = await _client.get(
      Uri.parse('$_base/users/me'),
      headers: await _authHeaders(),
    );
    return UserModel.fromJson(_decode(response));
  }

  /// PUT /users
  ///
  /// Updates the authenticated user's profile and settings.
  Future<void> updateUserSettings({
    String? name,
    String? avatar,
    bool? trackingEnabled,
    String? visibilityLevel,
    String? precisionLevel,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (avatar != null) body['avatar'] = avatar;
    if (trackingEnabled != null) body['tracking_enabled'] = trackingEnabled;
    if (visibilityLevel != null) body['visibility_level'] = visibilityLevel;
    if (precisionLevel != null) body['precision_level'] = precisionLevel;

    final response = await _client.put(
      Uri.parse('$_base/users'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );
    _decode(response);
  }

  /// PUT /users - Deprecated old method
  Future<Map<String, dynamic>> updateUser({
    String? name,
    String? avatar,
  }) async {
    return updateUserSettings(name: name, avatar: avatar).then((_) => {});
  }

  // ── Location ──────────────────────────────────────────────────────────────

  /// POST /locations
  ///
  /// Reports the current user's GPS position to the backend.
  /// Called periodically by [LocationTrackingService].
  Future<void> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _client.post(
      Uri.parse('$_base/locations'),
      headers: await _authHeaders(),
      body: jsonEncode({'latitude': latitude, 'longitude': longitude}),
    );
    _decode(response); // throws on error
  }

  // ── Invites ───────────────────────────────────────────────────────────────

  /// POST /invites/{user_id}
  ///
  /// Sends a friend request to [userId].
  Future<void> sendInvite(String userId) async {
    final response = await _client.post(
      Uri.parse('$_base/invites/${Uri.encodeComponent(userId)}'),
      headers: await _authHeaders(),
    );
    _decode(response);
  }

  /// GET /invites/{user_id}
  ///
  /// Returns a list of raw JSON maps for incoming/outgoing requests.
  /// Decode with [InviteModel.fromJson] on the caller side.
  Future<List<dynamic>> getInvites(String userId) async {
    final response = await _client.get(
      Uri.parse('$_base/invites/${Uri.encodeComponent(userId)}'),
      headers: await _authHeaders(),
    );
    return _decodeList(response);
  }

  /// POST /invites/{user_id}/accept
  Future<void> acceptInvite(String userId) async {
    final response = await _client.post(
      Uri.parse('$_base/invites/${Uri.encodeComponent(userId)}/accept'),
      headers: await _authHeaders(),
    );
    _decode(response);
  }

  /// POST /invites/{user_id}/decline
  Future<void> declineInvite(String userId) async {
    final response = await _client.post(
      Uri.parse('$_base/invites/${Uri.encodeComponent(userId)}/decline'),
      headers: await _authHeaders(),
    );
    _decode(response);
  }

  // ── Friends ───────────────────────────────────────────────────────────────

  /// GET /friends
  ///
  /// Returns a raw JSON list of friends with their last known lat/lng.
  /// Decode with [FriendModel.fromJson] on the caller side.
  Future<List<dynamic>> getFriends() async {
    final response = await _client.get(
      Uri.parse('$_base/friends'),
      headers: await _authHeaders(),
    );
    return _decodeList(response);
  }

  /// DELETE /friends/{id}
  ///
  /// Removes the friend with [friendId] from the current user's list.
  Future<void> removeFriend(String friendId) async {
    final response = await _client.delete(
      Uri.parse('$_base/friends/$friendId'),
      headers: await _authHeaders(),
    );
    _decode(response);
  }
}
