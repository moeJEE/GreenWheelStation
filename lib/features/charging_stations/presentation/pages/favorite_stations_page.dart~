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
    setState(() => _isLoading = true);
    
    try {
      final userFavoriteIds = await _stationService.getFavoriteStationIds();
      print('userFavoriteIds: $userFavoriteIds');


      final List<Map<String, dynamic>?> stations = await Future.wait(
        userFavoriteIds.map((id) async {
          Map<String, dynamic>? data = await _stationService.getStationDetails(id);
          if (data != null) {
            data['id'] = id; // Ensure the ID is set correctly
          }
          return data; // Return the single map, not a list
        }),
      );

      print('stations: $stations');
      if (mounted) {
        setState(() {
          _favoriteStations = stations
              .where((station) => station != null)
              .map((json) => Station.fromJson(json!['id'] as String, json))
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading favorite stations: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removeFromFavorites(String stationId) async {
    try {
      await _stationService.removeFromFavorites(stationId);
      await _loadFavoriteStations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Station removed from favorites'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing station: $e'),
            backgroundColor: Colors.red,
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No favorite stations yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add stations to your favorites to see them here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.map),
            icon: const Icon(Icons.map),
            label: const Text('Find Stations'),
          ),
        ],
      ),
    );
  }

  Widget _buildStationList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _favoriteStations.length,
      itemBuilder: (context, index) {
        final station = _favoriteStations[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: station.available ? Colors.green : Colors.red,
              child: const Icon(
                Icons.ev_station,
                color: Colors.white,
              ),
            ),
            title: Text(
              station.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(station.address),
                const SizedBox(height: 4),
                Text(
                  '${station.power} kW • ${station.pricePerKwh} MAD/kWh',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.map_outlined),
                  onPressed: () => _showOnMap(station),
                  tooltip: 'Show on Map',
                ),
                IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.red),
                  onPressed: () => _removeFromFavorites(station.id),
                  tooltip: 'Remove from Favorites',
                ),
              ],
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.stationDetails,
                arguments: station.id,
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Stations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadFavoriteStations,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFavoriteStations,
              child: _favoriteStations.isEmpty
                  ? _buildEmptyState()
                  : _buildStationList(),
            ),
    );
  }
}
