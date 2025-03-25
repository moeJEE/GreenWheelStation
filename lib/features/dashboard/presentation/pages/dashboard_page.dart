import 'package:flutter/material.dart';
import 'package:ev_charging_app/core/models/notification.dart';
import 'package:ev_charging_app/core/services/notification_service.dart';
import 'package:ev_charging_app/core/services/station_service.dart';
import 'package:ev_charging_app/core/services/location_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ev_charging_app/features/profile/presentation/pages/profile_page.dart';
import 'package:ev_charging_app/features/charging_stations/presentation/pages/favorite_stations_page.dart';
import 'package:ev_charging_app/features/charging_stations/presentation/pages/qr_scanner_page.dart';
import 'package:ev_charging_app/core/models/station.dart';
import 'package:ev_charging_app/features/assistant/presentation/pages/assistant_page.dart';

import '../../../../core/app_assets/app_assets.dart';
import '../../../charging_stations/presentation/pages/station_details_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _notificationService = NotificationService();
  final _stationService = StationService();
  final _locationService = LocationService();
  final _searchController = TextEditingController();
  late List<EVNotification> _notifications;
  bool _showNotifications = false;
  int _currentIndex = 0;
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  Position? _currentPosition;
  List<Station> _nearbyStations = [];
  bool _isSearching = false;
  late BitmapDescriptor carMarkerIcon;
  late BitmapDescriptor stationMarkerIcon;
  late BitmapDescriptor
      nearestStationMarkerIcon; // New icon for nearest station
  Station? _nearestStation; // Track the nearest station
  Map<String, double> _stationDistances = {}; // Track distances to all stations

  // Initial camera position (Morocco center)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(31.7917, -7.0926),
    zoom: 6.0,
  );

  @override
  void initState() {
    super.initState();
    _notifications = _notificationService.getDemoNotifications();
    _initMarkerIcons();
    //_getCurrentLocation();
  }

  Future<void> _initMarkerIcons() async {
    carMarkerIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(),
      AppAssets.car,
    );
    stationMarkerIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(),
      AppAssets.evChargerAvailable,
    );
    // Initialize nearest station marker with a different icon
    nearestStationMarkerIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(),
      AppAssets
          .evChargerAvailable, // You might want to use a different asset for the nearest station
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Vérifier et demander les permissions d'abord
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Les permissions sont refusées
          print('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Les permissions sont refusées définitivement
        print(
            'Location permissions are permanently denied, we cannot request permissions.');
        // Informez l'utilisateur qu'il doit activer manuellement les permissions
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Please enable location permissions in settings')),
          );
        }
        return;
      }

      // Vérifier si la localisation est activée
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // La localisation n'est pas activée
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Location services are disabled. Please enable them.')),
          );
        }
        return;
      }

      // Maintenant, obtenez la position
      final position = await Geolocator.getCurrentPosition();
      setState(() => _currentPosition = position);

      if (_mapController != null) {
        _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            14.0,
          ),
        );

        _searchNearbyStations(position.latitude, position.longitude);
      }
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  Future<void> _searchCity(String cityName) async {
    setState(() => _isSearching = true);

    try {
      final cityLocation = await _locationService.getCityLocation(cityName);
      if (cityLocation != null) {
        // Move camera to city location
        await _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(cityLocation, 14.0),
        );

        // Search for stations near the city
        await _searchNearbyStations(
          cityLocation.latitude,
          cityLocation.longitude,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('City not found. Please try another city name.')),
          );
        }
      }
    } catch (e) {
      print('Error searching city: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error searching city. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _searchNearbyStations(double lat, double lng) async {
    setState(() => _isSearching = true);
    try {
      final stations = await _stationService.getNearbyStations(
        lat,
        lng,
        radius: 10, // 10km radius
      );

      if (mounted) {
        setState(() {
          _nearbyStations = stations;

          // Calculate distances and find nearest station
          _calculateDistances(lat, lng, stations);

          // Update markers after distances are calculated
          _updateMarkers();
        });
      }
    } catch (e) {
      print('Error searching nearby stations: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Error finding nearby stations. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  // New method to calculate distances to all stations and identify nearest
  void _calculateDistances(double lat, double lng, List<Station> stations) {
    if (stations.isEmpty) {
      _nearestStation = null;
      _stationDistances = {};
      return;
    }

    double nearestDistance = double.infinity;
    Station? nearest;
    Map<String, double> distances = {};

    for (final station in stations) {
      final distance = Geolocator.distanceBetween(
          lat, lng, station.latitude, station.longitude);

      distances[station.id] = distance;

      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = station;
      }
    }

    _nearestStation = nearest;
    _stationDistances = distances;
  }

  void _updateMarkers() {
    _markers.clear();

    // Add station markers
    for (final station in _nearbyStations) {
      final isNearest = station.id == _nearestStation?.id;
      final distance = _stationDistances[station.id];
      String distanceText = '';

      if (distance != null) {
        distanceText = distance < 1000
            ? '${distance.toStringAsFixed(0)}m'
            : '${(distance / 1000).toStringAsFixed(1)}km';
      }

      _markers.add(
        Marker(
          markerId: MarkerId(station.id),
          position: LatLng(station.latitude, station.longitude),
          icon: isNearest ? nearestStationMarkerIcon : stationMarkerIcon,
          onTap: () {
            print('Marker tapped: ${station.name}');
            // Open bottom sheet to display station info and ask if you want to see details
            showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return _buildStationDetailsBottomSheet(station);
              },
            );
          },
          infoWindow: InfoWindow(
            title: station.name,
            snippet:
                '${station.power}kW • ${station.pricePerKwh}MAD/kWh${distanceText.isNotEmpty ? ' • $distanceText' : ''}',
          ),
        ),
      );
    }

    // Add current location marker if we're showing the user's location
    if (_currentPosition != null && _searchController.text.isEmpty) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          icon: carMarkerIcon,
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () {
                    setState(() {
                      _showNotifications = !_showNotifications;
                    });
                  },
                ),
                if (_notificationService.getUnreadCount() > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${_notificationService.getUnreadCount()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        body: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: [
                // Dashboard Content
                Column(
                  children: [
                    Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF4CAF50), // Primary green
                            Color(0xFF66BB6A), // Secondary green
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              AppAssets.evCharging,
                              fit: BoxFit.contain,
                              opacity: const AlwaysStoppedAnimation(0.3),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Welcome Back!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Find the nearest charging station for your EV',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    _buildStatCard(
                                      'Battery Level',
                                      '75%',
                                      Icons.battery_charging_full,
                                    ),
                                    const SizedBox(width: 16),
                                    _nearestStation != null
                                        ? _buildNearestStationCard()
                                        : _buildStatCard(
                                            'Range',
                                            '150 km',
                                            Icons.speed,
                                          ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          GoogleMap(
                            initialCameraPosition: _initialPosition,
                            onMapCreated: (controller) {
                              _mapController = controller;
                              Future.delayed(const Duration(milliseconds: 300),
                                  () {
                                _getCurrentLocation();
                              });
                            },
                            markers: _markers,
                            myLocationEnabled: true,
                            myLocationButtonEnabled: true,
                          ),
                          if (_isSearching)
                            const Center(
                              child: Card(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ),
                          Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(color: Colors.black87),
                              decoration: InputDecoration(
                                hintText: 'Search by city name...',
                                hintStyle: const TextStyle(color: Colors.black),
                                prefixIcon: const Icon(Icons.search,
                                    color: Colors.black),
                                suffixIcon: _isSearching
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    : IconButton(
                                        icon: const Icon(Icons.clear,
                                            color: Colors.black87),
                                        onPressed: () {
                                          _searchController.clear();
                                          _getCurrentLocation();
                                        },
                                      ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide:
                                      const BorderSide(color: Colors.white),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide:
                                      const BorderSide(color: Colors.white),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: const BorderSide(
                                      color: Colors.white, width: 2),
                                ),
                              ),
                              onSubmitted: (value) {
                                if (value.isNotEmpty) {
                                  _searchCity(value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Favorites
                const FavoriteStationsPage(),
                // Profile
                const ProfilePage(),
                // Assistant
                const AssistantPage(),
              ],
            ),
            if (_showNotifications)
              Positioned(
                top: 0,
                right: 0,
                child: Card(
                  margin: const EdgeInsets.only(top: 8, right: 8),
                  elevation: 8,
                  child: Container(
                    width: 300,
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.6,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.withOpacity(0.2),
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Notifications',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // Mark all as read
                                },
                                child: const Text('Mark all as read'),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _notifications.length,
                            itemBuilder: (context, index) {
                              final notification = _notifications[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      _getNotificationColor(notification.type),
                                  child: Icon(
                                    _getNotificationIcon(notification.type),
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  notification.title,
                                  style: TextStyle(
                                    fontWeight: notification.isRead
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(notification.message),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatTimestamp(notification.timestamp),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                tileColor: notification.isRead
                                    ? null
                                    : Colors.blue.withOpacity(0.1),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        floatingActionButton: _currentIndex == 0
            ? Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FloatingActionButton(
                    heroTag: 'qr_scanner',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const QRScannerPage()),
                      );
                    },
                    child: const Icon(Icons.qr_code_scanner),
                  ),
                  const SizedBox(height: 16),
                  FloatingActionButton(
                    heroTag: 'nearest_station',
                    onPressed: () {
                      _navigateToNearestStation();
                    },
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.location_searching),
                  ),
                ],
              )
            : _currentIndex == 1
                ? FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const QRScannerPage()),
                      );
                    },
                    child: const Icon(Icons.qr_code_scanner),
                  )
                : null,
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed, // Forces fixed mode
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: Colors.black, // Customize as needed
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assistant),
              label: 'Assistant',
            ),
          ],
        ));
  }

  // New method to navigate to the nearest station
  void _navigateToNearestStation() {
    if (_nearestStation != null) {
      // First zoom to the station
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_nearestStation!.latitude, _nearestStation!.longitude),
          16.0,
        ),
      );

      // Then show the bottom sheet with details
      Future.delayed(const Duration(milliseconds: 500), () {
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return _buildStationDetailsBottomSheet(_nearestStation!);
          },
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No nearby stations found'),
        ),
      );
    }
  }

  // New method to build the nearest station card
  Widget _buildNearestStationCard() {
    if (_nearestStation == null) {
      return const SizedBox();
    }

    final distance = _stationDistances[_nearestStation!.id] ?? 0;
    final formattedDistance = distance < 1000
        ? '${distance.toStringAsFixed(0)}m'
        : '${(distance / 1000).toStringAsFixed(1)}km';

    return Expanded(
      child: GestureDetector(
        onTap: _navigateToNearestStation,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.ev_station, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nearest Station',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      formattedDistance,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow
                          .ellipsis, // Corrected from TextWeight to TextOverflow
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'warning':
        return Colors.orange;
      case 'success':
        return Colors.green;
      case 'info':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'warning':
        return Icons.warning;
      case 'success':
        return Icons.check_circle;
      case 'info':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  // Enhanced StationDetailsBottomSheet with distance information
  Widget _buildStationDetailsBottomSheet(Station station) {
    final distance = _stationDistances[station.id];
    String distanceText = '';

    if (distance != null) {
      distanceText = distance < 1000
          ? '${distance.toStringAsFixed(0)} meters away'
          : '${(distance / 1000).toStringAsFixed(1)} km away';
    }

    bool isNearest = station.id == _nearestStation?.id;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isNearest)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green),
              ),
              child: const Text(
                'Nearest Station',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Text(
            station.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${station.power}kW • ${station.pricePerKwh}MAD/kWh',
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          if (distanceText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              distanceText,
              style: TextStyle(
                fontSize: 16,
                color: isNearest ? Colors.green : Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            station.address,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.favorite_border),
                label: const Text('Add to favorite'),
                onPressed: () {
                  // Add to favorites logic here
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('${station.name} added to favorites')),
                  );
                  Navigator.pop(context);
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.directions),
                label: const Text('Directions'),
                onPressed: () {
                  // Navigate to station details page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          StationDetailsPage(station: station),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
