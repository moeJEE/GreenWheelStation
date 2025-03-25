import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ev_charging_app/core/models/station.dart';
import 'package:ev_charging_app/core/services/station_service.dart';
import 'package:ev_charging_app/features/charging_stations/presentation/pages/station_details_page.dart';

import '../../../../core/app_assets/app_assets.dart';

class MapPage extends StatefulWidget {
  final LatLng? initialLocation;
  final List<Station> stations;
  final Position? currentLocation;

  const MapPage({
    super.key,
    this.initialLocation,
    required this.stations,
    this.currentLocation,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _stationService = StationService();
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  Station? _selectedStation;
  BitmapDescriptor? _carIcon;

  @override
  void initState() {
    super.initState();
    _loadCarIcon();
    _initializeMarkers();
  }

  Future<void> _loadCarIcon() async {
    final Uint8List markerIcon = await getBytesFromAsset(AppAssets.car, 80);
    _carIcon = BitmapDescriptor.fromBytes(markerIcon);
    _initializeMarkers(); // Reinitialize markers with the car icon
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  void _initializeMarkers() {
    _markers = widget.stations.map((station) {
      return Marker(
        markerId: MarkerId(station.id),
        position: LatLng(station.latitude, station.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          station.available ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
        ),
        onTap: () => _showStationBottomSheet(station),
      );
    }).toSet();

    // Add current location marker if available
    if (widget.currentLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            widget.currentLocation!.latitude,
            widget.currentLocation!.longitude,
          ),
          icon: _carIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }
    
    if (mounted) setState(() {});
  }

  void _showStationBottomSheet(Station station) {
    setState(() => _selectedStation = station);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBottomSheet(station),
    );
  }

  Widget _buildBottomSheet(Station station) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.75,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        station.address,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                FutureBuilder<bool>(
                  future: _stationService.isFavorite(station.id),
                  builder: (context, snapshot) {
                    final isFavorite = snapshot.data ?? false;
                    return IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: Colors.red,
                      ),
                      onPressed: () async {
                        if (isFavorite) {
                          await _stationService.removeFromFavorites(station.id);
                        } else {
                          await _stationService.addToFavorites(station.id);
                        }
                        setState(() {}); // Refresh to update favorite status
                      },
                    );
                  },
                ),
              ],
            ),
            const Divider(height: 32),
            _buildInfoRow(
              Icons.electric_bolt,
              'Power',
              '${station.power} kW',
            ),
            _buildInfoRow(
              Icons.attach_money,
              'Price',
              '${station.pricePerKwh} MAD/kWh',
            ),
            _buildInfoRow(
              Icons.ev_station,
              'Status',
              station.available ? 'Available' : 'Occupied',
              color: station.available ? Colors.green : Colors.red,
            ),
            _buildInfoRow(
              Icons.cable,
              'Connectors',
              station.connectorTypes.join(', '),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Navigate to station details page
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StationDetailsPage(
                      station: station,
                      currentLocation: widget.currentLocation,
                    ),
                  ),
                );
              },
              child: const Text('View Details'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.grey[600]),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color ?? Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    
    if (widget.stations.length == 1) {
      // If showing a single station, zoom to it
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(
            widget.stations.first.latitude,
            widget.stations.first.longitude,
          ),
          15,
        ),
      );
    } else if (widget.stations.length > 1) {
      // If showing multiple stations, fit bounds to show all
      _fitBounds();
    }
  }

  void _fitBounds() {
    if (widget.stations.isEmpty) return;

    double minLat = widget.stations.first.latitude;
    double maxLat = widget.stations.first.latitude;
    double minLng = widget.stations.first.longitude;
    double maxLng = widget.stations.first.longitude;

    for (final station in widget.stations) {
      if (station.latitude < minLat) minLat = station.latitude;
      if (station.latitude > maxLat) maxLat = station.latitude;
      if (station.longitude < minLng) minLng = station.longitude;
      if (station.longitude > maxLng) maxLng = station.longitude;
    }

    // Include current location in bounds if available
    if (widget.currentLocation != null) {
      final lat = widget.currentLocation!.latitude;
      final lng = widget.currentLocation!.longitude;
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    _mapController.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50, // padding
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Charging Stations'),
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: widget.initialLocation ??
              const LatLng(33.981535, -6.716713), // Default to UIR location
          zoom: 12,
        ),
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}
