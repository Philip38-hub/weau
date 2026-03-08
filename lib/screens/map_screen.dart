import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/friend_provider.dart';
import '../services/location_tracking_service.dart';
import '../core/api_service.dart';
import 'friends_screen.dart';
import 'invites_screen.dart';
import 'login_screen.dart';

/// Main map screen.
///
/// - Starts the 5-second location upload loop via [LocationTrackingService].
/// - Refreshes friend markers every 10 seconds.
/// - Displays a bottom navigation bar to switch to Friends / Invites.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  late final LocationTrackingService _locationService;
  Timer? _mapRefreshTimer;
  int _navIndex = 0;

  static const _initialCamera = CameraPosition(
    target: LatLng(0, 0),
    zoom: 3,
  );

  @override
  void initState() {
    super.initState();
    _locationService = LocationTrackingService(
      apiService: context.read<ApiService>(),
    );
    _startServices();
  }

  Future<void> _startServices() async {
    await _locationService.start();
    // Initial fetch right away, then every 10 seconds.
    _fetchFriends();
    _mapRefreshTimer = Timer.periodic(
      const Duration(seconds: AppConstants.mapRefreshIntervalSeconds),
      (_) => _fetchFriends(),
    );
  }

  void _fetchFriends() {
    context.read<FriendProvider>().fetchFriends();
  }

  @override
  void dispose() {
    _locationService.stop();
    _mapRefreshTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ── Map helpers ────────────────────────────────────────────────────────────

  Set<Marker> _buildMarkers(FriendProvider fp) {
    return fp.friends
        .where((f) => f.latitude != null && f.longitude != null)
        .map(
          (f) => Marker(
            markerId: MarkerId(f.id),
            position: LatLng(f.latitude!, f.longitude!),
            infoWindow: InfoWindow(
              title: f.name,
              snippet: f.lastSeen != null
                  ? 'Last seen: ${_formatTime(f.lastSeen!)}'
                  : null,
            ),
          ),
        )
        .toSet();
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  // ── Sign-out ───────────────────────────────────────────────────────────────

  Future<void> _signOut() async {
    _locationService.stop();
    _mapRefreshTimer?.cancel();
    final auth = context.read<AuthProvider>();
    final friends = context.read<FriendProvider>();
    await auth.signOut();
    friends.clear();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('weau'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: _signOut,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people), label: 'Friends'),
          BottomNavigationBarItem(
              icon: Icon(Icons.mail), label: 'Invites'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_navIndex) {
      case 1:
        return const FriendsScreen();
      case 2:
        return const InvitesScreen();
      default:
        return _buildMap();
    }
  }

  Widget _buildMap() {
    return Consumer<FriendProvider>(
      builder: (_, fp, __) {
        return GoogleMap(
          initialCameraPosition: _initialCamera,
          onMapCreated: (c) => _mapController = c,
          markers: _buildMarkers(fp),
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
        );
      },
    );
  }
}
