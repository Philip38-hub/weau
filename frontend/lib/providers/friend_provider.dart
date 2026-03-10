import 'package:flutter/foundation.dart';
import '../core/api_service.dart';
import '../models/friend_model.dart';
import '../models/invite_model.dart';

/// Manages the friends list and invite state.
///
/// Expose this provider above the routes that need it, for example in
/// [MultiProvider] alongside [AuthProvider].
class FriendProvider extends ChangeNotifier {
  final ApiService _api;

  FriendProvider({required ApiService apiService}) : _api = apiService;

  // ── State ──────────────────────────────────────────────────────────────────

  List<FriendModel> _friends = [];
  List<InviteModel> _invites = [];
  bool _isLoadingFriends = false;
  bool _isLoadingInvites = false;
  String? _error;

  // ── Getters ────────────────────────────────────────────────────────────────

  List<FriendModel> get friends => List.unmodifiable(_friends);
  List<InviteModel> get invites => List.unmodifiable(_invites);
  List<InviteModel> get incomingInvites =>
      _invites.where((i) => i.direction == InviteDirection.incoming).toList();
  List<InviteModel> get outgoingInvites =>
      _invites.where((i) => i.direction == InviteDirection.outgoing).toList();
  bool get isLoadingFriends => _isLoadingFriends;
  bool get isLoadingInvites => _isLoadingInvites;
  String? get error => _error;

  // ── Friends ────────────────────────────────────────────────────────────────

  /// Fetches the friends list. Call this to refresh map markers every 10 s.
  Future<void> fetchFriends() async {
    _isLoadingFriends = true;
    notifyListeners();
    try {
      final raw = await _api.getFriends();
      _friends = raw
          .map((e) => FriendModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingFriends = false;
      notifyListeners();
    }
  }

  /// Removes a friend both locally and on the backend.
  Future<void> removeFriend(String friendId) async {
    try {
      await _api.removeFriend(friendId);
      _friends.removeWhere((f) => f.id == friendId);
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  // ── Invites ────────────────────────────────────────────────────────────────

  /// Fetches invites for [userId] (typically the signed-in user's own ID).
  Future<void> fetchInvites(String userId) async {
    _isLoadingInvites = true;
    notifyListeners();
    try {
      final raw = await _api.getInvites(userId);
      _invites = raw
          .map((e) => InviteModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingInvites = false;
      notifyListeners();
    }
  }

  /// Sends a friend request to [userId].
  Future<void> sendInvite(String userId) async {
    try {
      await _api.sendInvite(userId);
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  /// Accepts the invite from [userId] and refreshes the invites list.
  Future<void> acceptInvite(String userId) async {
    try {
      await _api.acceptInvite(userId);
      _invites.removeWhere((i) => i.userId == userId);
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  /// Declines the invite from [userId] and removes it locally.
  Future<void> declineInvite(String userId) async {
    try {
      await _api.declineInvite(userId);
      _invites.removeWhere((i) => i.userId == userId);
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  /// Clears all data on sign-out.
  void clear() {
    _friends = [];
    _invites = [];
    _error = null;
    notifyListeners();
  }
}
