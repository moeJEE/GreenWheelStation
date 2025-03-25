import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:ev_charging_app/core/models/station.dart';
import 'package:ev_charging_app/core/services/station_service.dart';
import 'package:ev_charging_app/features/charging_stations/presentation/pages/map_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ev_charging_app/core/routes/app_routes.dart';

class FavoriteStationsPage extends StatefulWidget {
  const FavoriteStationsPage({super.key});

  @override
  State<FavoriteStationsPage> createState() => _FavoriteStationsPageState();
}

class _FavoriteStationsPageState extends State<FavoriteStationsPage> {
  late final StationService _stationService;
  List<Station> _favoriteStations = [];
  Position? _currentLocation;
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _stationService = Provider.of<StationService>(context, listen: false);
    _loadFavoriteStations();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() => _currentLocation = position);
      }
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  Future<void> _loadFavoriteStations() async {
    if (!mounted) return;
    setState(() {
      _isLoading = !_isRefreshing;
      _isRefreshing = false;
    });
    
    try {
      final userFavoriteIds = await _stationService.getFavoriteStationIds();

      final List<Map<String, dynamic>?> stations = await Future.wait(
        userFavoriteIds.map((id) async {
          Map<String, dynamic>? data = await _stationService.getStationDetails(id);
          if (data != null) {
            data['id'] = id; // Ensure the ID is set correctly
          }
          return data;
        }),
      );

      if (mounted) {
        setState(() {
          _favoriteStations = stations
              .where((station) => station != null)
              .map((json) => Station.fromJson(json!['id'] as String, json))
              .toList();
        });
      }
    } catch (e) {
      print('Error loading favorite stations: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error loading favorite stations: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(12),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshStations() async {
    setState(() => _isRefreshing = true);
    await _loadFavoriteStations();
  }

  Future<void> _removeFromFavorites(String stationId, String stationName) async {
    try {
      await _stationService.removeFromFavorites(stationId);
      await _loadFavoriteStations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('$stationName removed from favorites'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(12),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error removing station: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(12),
          ),
        );
      }
    }
  }

  void _showOnMap(Station station) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPage(
          initialLocation: LatLng(station.latitude, station.longitude),
          stations: [station],
          currentLocation: _currentLocation,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey[50]!,
            Colors.grey[100]!,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.favorite_border,
                  size: 56,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Favorite Stations Yet',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  'Add charging stations to your favorites to access them quickly and track their availability',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.map),
                icon: const Icon(Icons.map),
                label: const Text('Explore Stations'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildStationCard(Station station) {
  return Card(
    elevation: 2,
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.white,
            station.available 
                ? Colors.green.withOpacity(0.05) 
                : Colors.red.withOpacity(0.05),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            leading: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: station.available 
                    ? const Color(0xFF4CAF50)
                    : Colors.red[400],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (station.available 
                        ? const Color(0xFF4CAF50) 
                        : Colors.red[400]!).withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.ev_station,
                color: Colors.white,
                size: 28,
              ),
            ),
            title: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                station.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  station.address,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: station.available
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    station.available ? 'Available' : 'Unavailable',
                    style: TextStyle(
                      color: station.available
                          ? Colors.green[700]
                          : Colors.red[700],
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.bolt,
                  size: 20,
                  color: Colors.amber[700],
                ),
                const SizedBox(width: 4),
                Text(
                  '${station.power} kW',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.payments_outlined,
                  size: 20,
                  color: Colors.green[700],
                ),
                const SizedBox(width: 4),
                Text(
                  '${station.pricePerKwh} MAD/kWh',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
                if (_currentLocation != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.directions_car,
                    size: 20,
                    color: Colors.blue[700],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(Geolocator.distanceBetween(
                          _currentLocation!.latitude,
                          _currentLocation!.longitude,
                          station.latitude,
                          station.longitude,
                        ) / 1000).toStringAsFixed(1)} km',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.stationDetails,
                        arguments: station.id,
                      );
                    },
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Details'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue[700],
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _showOnMap(station),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Map'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue[700],
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _removeFromFavorites(station.id, station.name),
                    icon: const Icon(Icons.favorite),
                    label: const Text('Remove'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red[400],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildStationList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _favoriteStations.length + 1, // +1 for the header
      itemBuilder: (context, index) {
        if (index == 0) {
          // Header with count and last updated info
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.favorite,
                        size: 16,
                        color: Color(0xFF4CAF50),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_favoriteStations.length} Stations',
                        style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'Pull to refresh',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.refresh,
                  size: 14,
                  color: Colors.grey[600],
                ),
              ],
            ),
          );
        }
        
        final station = _favoriteStations[index - 1];
        return _buildStationCard(station);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: const Color(0xFF4CAF50),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          foregroundColor: Colors.black87,
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Favorite Stations'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isLoading || _isRefreshing ? null : _refreshStations,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: _isLoading
            ? Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey[50]!,
                      Colors.grey[100]!,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF4CAF50),
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _refreshStations,
                color: const Color(0xFF4CAF50),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey[50]!,
                        Colors.grey[100]!,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: _favoriteStations.isEmpty
                      ? _buildEmptyState()
                      : _buildStationList(),
                ),
              ),
      ),
    );
  }
}