import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ev_charging_app/core/models/station.dart';
import 'package:ev_charging_app/core/services/station_service.dart';

class StationDetailsPage extends StatefulWidget {
  final Station station;
  final Position? currentLocation;

  const StationDetailsPage({
    super.key,
    required this.station,
    this.currentLocation,
  });

  @override
  State<StationDetailsPage> createState() => _StationDetailsPageState();
}

class _StationDetailsPageState extends State<StationDetailsPage> with SingleTickerProviderStateMixin {
  final _stationService = StationService();
  bool _isFavorite = false;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
    
    // Initialize animation for the status indicator
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkFavoriteStatus() async {
    final isFavorite = await _stationService.isFavorite(widget.station.id);
    if (mounted) {
      setState(() {
        _isFavorite = isFavorite;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    setState(() => _isLoading = true);
    
    try {
      if (_isFavorite) {
        await _stationService.removeFromFavorites(widget.station.id);
      } else {
        await _stationService.addToFavorites(widget.station.id);
      }
      
      if (mounted) {
        setState(() => _isFavorite = !_isFavorite);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openInMaps() async {
    final station = widget.station;
    final currentLocation = widget.currentLocation;
    
    String url;
    if (currentLocation != null) {
      // If we have current location, provide navigation
      url = 'https://www.google.com/maps/dir/?api=1'
          '&origin=${currentLocation.latitude},${currentLocation.longitude}'
          '&destination=${station.latitude},${station.longitude}'
          '&travelmode=driving';
    } else {
      // Otherwise just show the station location
      url = 'https://www.google.com/maps/search/?api=1'
          '&query=${station.latitude},${station.longitude}';
    }

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open maps'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF4CAF50);
    
    return Theme(
      data: Theme.of(context).copyWith(
        primaryColor: primaryColor,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          foregroundColor: Colors.black87,
          titleTextStyle: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.station.name),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                  )
                : Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : Colors.grey[600],
                  ),
              onPressed: _isLoading ? null : _toggleFavorite,
            ),
          ],
        ),
        body: Container(
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top banner with station info
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor,
                        Color(0xFF66BB6A),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.ev_station,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.station.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              widget.station.address,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Enhanced Map
                Container(
                  height: 220,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          widget.station.latitude,
                          widget.station.longitude,
                        ),
                        zoom: 15,
                      ),
                      markers: {
                        Marker(
                          markerId: MarkerId(widget.station.id),
                          position: LatLng(
                            widget.station.latitude,
                            widget.station.longitude,
                          ),
                          infoWindow: InfoWindow(title: widget.station.name),
                        ),
                      },
                      mapType: MapType.normal,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      compassEnabled: false,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Station details in cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          'Power',
                          Text(
                            '${widget.station.power} kW',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          icon: Icons.electric_bolt,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoCard(
                          'Price',
                          Text(
                            '${widget.station.pricePerKwh} MAD/kWh',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.amber[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          icon: Icons.attach_money,
                          color: Colors.amber[700]!,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Enhanced status card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildInfoCard(
                    'Status',
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: widget.station.available ? _pulseAnimation.value : 1.0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: widget.station.available 
                                  ? [Colors.green.shade400, Colors.green.shade600]
                                  : [Colors.red.shade400, Colors.red.shade600],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.station.available 
                                    ? Colors.green.withOpacity(0.3)
                                    : Colors.red.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      widget.station.available ? Icons.check_circle : Icons.cancel,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      widget.station.available ? 'Available' : 'Unavailable',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                if (widget.station.availableStatus != null && 
                                    widget.station.availableStatus!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      widget.station.availableStatus!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    icon: Icons.info_outline,
                    color: widget.station.available ? Colors.green : Colors.red,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Connector types
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildInfoCard(
                    'Connector Types',
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.station.connectorTypes.map((type) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            type,
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    icon: Icons.electrical_services,
                    color: primaryColor,
                  ),
                ),
                
                // Extra space at bottom for FAB
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openInMaps,
          icon: const Icon(Icons.directions),
          label: const Text('Navigate'),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, Widget content, {required IconData icon, required Color color}) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Center(child: content),
          ],
        ),
      ),
    );
  }
}