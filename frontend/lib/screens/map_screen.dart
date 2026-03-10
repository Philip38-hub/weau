import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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
import 'settings_screen.dart';

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
  bool _isPreparingMap = true;
  bool _hasCenteredOnUser = false;
  bool _myLocationEnabled = false;
  LatLng? _currentUserLatLng;

  static const _fallbackCamera = CameraPosition(
    target: LatLng(0, 0),
    zoom: 3,
  );
  static const double _townZoom = 15.5;

  CameraPosition _initialCameraPosition = _fallbackCamera;

  // ── Premium Dark Style ──────────────────────────────────────────────────────
  static const String _darkMapStyle = '''
[
  { "elementType": "geometry", "stylers": [{ "color": "#12122a" }] },
  { "elementType": "labels.text.fill", "stylers": [{ "color": "#8ec3b9" }] },
  { "elementType": "labels.text.stroke", "stylers": [{ "color": "#12122a" }] },
  { "featureType": "administrative", "elementType": "geometry", "stylers": [{ "visibility": "off" }] },
  { "featureType": "poi", "stylers": [{ "visibility": "off" }] },
  { "featureType": "road", "elementType": "geometry", "stylers": [{ "color": "#1a1a3d" }] },
  { "featureType": "road", "elementType": "labels.text.fill", "stylers": [{ "color": "#9ca5b9" }] },
  { "featureType": "transit", "stylers": [{ "visibility": "off" }] },
  { "featureType": "water", "elementType": "geometry", "stylers": [{ "color": "#0d0d1f" }] }
]
''';

  @override
  void initState() {
    super.initState();
    _locationService = LocationTrackingService(
      apiService: context.read<ApiService>(),
    );
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await Future.wait([_startServices(), _prepareInitialCamera()]);
  }

  Future<void> _startServices() async {
    await _locationService.start();
    _fetchFriends();
    _mapRefreshTimer = Timer.periodic(
      const Duration(seconds: AppConstants.mapRefreshIntervalSeconds),
      (_) => _fetchFriends(),
    );
  }

  void _fetchFriends() {
    context.read<FriendProvider>().fetchFriends();
  }

  Future<void> _prepareInitialCamera() async {
    try {
      final Position? position = await _locationService.getCurrentPosition();
      if (!mounted) return;

      setState(() {
        if (position != null) {
          _currentUserLatLng = LatLng(position.latitude, position.longitude);
          _initialCameraPosition = CameraPosition(
            target: _currentUserLatLng!,
            zoom: _townZoom,
          );
          _myLocationEnabled = true;
        }
        _isPreparingMap = false;
      });

      await _moveCameraToUser();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isPreparingMap = false);
    }
  }

  Future<void> _moveCameraToUser() async {
    if (_mapController == null || _currentUserLatLng == null || _hasCenteredOnUser) {
      return;
    }

    _hasCenteredOnUser = true;
    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentUserLatLng!, zoom: _townZoom),
      ),
    );
  }

  @override
  void dispose() {
    _locationService.stop();
    _mapRefreshTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Set<Marker> _buildMarkers(FriendProvider fp) {
    final markers = fp.friends
        .where((f) => f.latitude != null && f.longitude != null)
        .map(
          (f) => Marker(
            markerId: MarkerId(f.id),
            position: LatLng(f.latitude!, f.longitude!),
            alpha: f.isBlurred ? 0.6 : 1.0,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              f.isBlurred ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueViolet,
            ),
            infoWindow: InfoWindow(
              title: f.name + (f.isBlurred ? " (Approximate)" : ""),
              snippet: f.lastSeen != null ? _formatTime(f.lastSeen!) : null,
            ),
          ),
        )
        .toSet();

    if (_currentUserLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current-user'),
          position: _currentUserLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRose,
          ),
          zIndexInt: 2,
          infoWindow: const InfoWindow(title: 'You'),
        ),
      );
    }

    return markers;
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: _navIndex == 0,
      appBar: _navIndex == 0
          ? AppBar(
              backgroundColor: scheme.surface.withValues(
                alpha: isDark ? 0.78 : 0.92,
              ),
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              title: const Text(
                'weau',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              actions: [
                IconButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                  icon: const Icon(Icons.settings_rounded),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: _signOut,
                ),
              ],
            )
          : AppBar(
              title: Text(_navIndex == 1 ? 'Friends' : 'Invites'),
              elevation: 4,
            ),
      body: _buildBody(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(
            top: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _navIndex,
          onTap: (i) => setState(() => _navIndex = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: scheme.primary,
          unselectedItemColor: scheme.onSurfaceVariant,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.radar_rounded), label: 'Map'),
            BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Friends'),
            BottomNavigationBarItem(icon: Icon(Icons.mail_outline_rounded), label: 'Invites'),
          ],
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isPreparingMap) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(AppConstants.primaryColor),
        ),
      );
    }

    return Consumer<FriendProvider>(
      builder: (_, fp, __) {
        return GoogleMap(
          initialCameraPosition: _initialCameraPosition,
          style: isDark ? _darkMapStyle : null,
          onMapCreated: (c) async {
            _mapController = c;
            await _moveCameraToUser();
          },
          markers: _buildMarkers(fp),
          myLocationEnabled: _myLocationEnabled,
          myLocationButtonEnabled: false, // will use custom floating button
          zoomControlsEnabled: false,
          compassEnabled: false,
        );
      },
    );
  }
}
