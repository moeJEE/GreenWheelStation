import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ev_charging_app/core/models/user.dart';
import 'dart:math';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Get user data
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      return docSnapshot.data();
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Update user data
  Future<void> updateUserData(Map<String, dynamic> data) async {
    if (currentUserId == null) throw 'user id not found in updateUserData';

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      print('Error updating user data: $e');
      rethrow;
    }
  }

// Get favorite station IDs
  Future<List<String>> getFavoriteStationIds() async {
    if (currentUserId == null) throw 'User ID not found in getFavoriteStationIds';

    try {
      final snapshot = await _firestore.collection('users').doc(currentUserId).get();

      // Ensure data exists and contains the favoriteStations field
      final data = snapshot.data();
      if (data == null || !data.containsKey('favoriteStations')) return [];

      // Safely cast the list from Firestore
      return List<String>.from(data['favoriteStations'] ?? []);
    } catch (e) {
      print('Error getting favorite stations: $e');
      return [];
    }
  }

  // Add to favorites
  Future<void> addToFavorites(String stationId) async {
    if (currentUserId == null) throw 'user id not found in getFavoriteStationIds';

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId).update(
        {
          'favoriteStations': FieldValue.arrayUnion([stationId]), // Append to list
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    } catch (e) {
      print('Error adding to favorites: $e');
      rethrow;
    }
  }

// Remove from favorites
  Future<void> removeFromFavorites(String stationId) async {
    if (currentUserId == null) return;

    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'favoriteStations': FieldValue.arrayRemove([stationId]), // Remove from list
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error removing from favorites: $e');
      rethrow;
    }
  }

// Check if station is favorite
  Future<bool> isFavoriteStation(String stationId) async {
    if (currentUserId == null) return false;

    try {
      final docSnapshot = await _firestore.collection('users').doc(currentUserId).get();

      if (!docSnapshot.exists) return false;

      final data = docSnapshot.data();
      if (data == null || !data.containsKey('favoriteStations')) return false;

      final List<dynamic> favoriteStations = data['favoriteStations'];
      return favoriteStations.contains(stationId);
    } catch (e) {
      print('Error checking favorite status: $e');
      return false;
    }
  }


  // Initialize user data
  Future<void> initializeUserData({
    required String userId,
    required String email,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final userDoc = _firestore.collection('users').doc(userId);
      final userSnapshot = await userDoc.get();

      if (!userSnapshot.exists) {
        await userDoc.set({
          'email': email,
          'firstName': firstName,
          'lastName': lastName,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error initializing user data: $e');
      throw 'Failed to initialize user data';
    }
  }

  // Get station details
  Future<Map<String, dynamic>?> getStationDetails(String id) async {
    try {
      final docSnapshot = await _firestore.collection('stations').doc(id).get();
      return docSnapshot.data();
    } catch (e) {
      print('Error getting station details: $e');
      return null;
    }
  }

  // Initialize demo stations
  Future<void> initializeDemoStations() async {
    try {
      final batch = _firestore.batch();
      final stationsRef = _firestore.collection('stations');

      // Demo station data
      final demoStations =

      [
        {
          "name": "Marjane IRESEN (Hay Riad)",
          "address": "Rocade de Rabat (Marjane Hay Riad), Rabat, Morocco",
          "latitude": 33.955,
          "longitude": -6.853,
          "available": true,
          "available_status": "Operational (Public)",
          "power": 22,
          "pricePerKwh": 0,
          "connectorTypes": ["Type 2"]
        },
        {
          "name": "IRESEN Headquarters",
          "address": "22 Avenue S.A.R. Sidi Mohamed, Rabat, Morocco",
          "latitude": 33.971,
          "longitude": -6.849,
          "available": true,
          "available_status": "Operational (Public, daytime access)",
          "power": 22,
          "pricePerKwh": 0,
          "connectorTypes": ["Type 2"]
        },
        {
          "name": "Sofitel Rabat Jardin Des Roses",
          "address": "Bp 450 Quartier Aviation, Rabat, Morocco",
          "latitude": 34.020882,
          "longitude": -6.84165,
          "available": true,
          "available_status": null,
          "power": 22,
          "pricePerKwh": 0,
          "connectorTypes": ["Type 2"]
        },
        {
          "name": "FastVolt Afriquia Rabat Al Melia",
          "address": "X49P+H8H, Avenue Al Melia, Rabat, Morocco",
          "latitude": 34.020,
          "longitude": -6.841,
          "available": true,
          "available_status": null,
          "power": 50,
          "pricePerKwh": 2.5,
          "connectorTypes": ["Type 2", "CCS"]
        },
        {
          "name": "Hotel El Minzah",
          "address": "11 Rue Lokous, Tangier, Morocco",
          "latitude": 35.774,
          "longitude": -5.802,
          "available": true,
          "available_status": null,
          "power": 22,
          "pricePerKwh": 0,
          "connectorTypes": ["Type 2"]
        },
        {
          "name": "Supercharger Tangier",
          "address": "Route sans nom, Tangier, Morocco",
          "latitude": 35.7595,
          "longitude": -5.833,
          "available": true,
          "available_status": "Operational (Public - Tesla only)",
          "power": 120,
          "pricePerKwh": 0.25,
          "connectorTypes": ["Tesla Supercharger"]
        },
        {
          "name": "Station Afriquia A5",
          "address": "Tangier, Morocco",
          "latitude": 35.7595,
          "longitude": -5.833,
          "available": true,
          "available_status": null,
          "power": 50,
          "pricePerKwh": 2.5,
          "connectorTypes": ["Type 2", "CCS"]
        },
        {
          "name": "Mövenpick Hotel and Casino",
          "address": "Avenue Mohamed VI, Tangier, Morocco",
          "latitude": 35.7595,
          "longitude": -5.833,
          "available": true,
          "available_status": null,
          "power": 22,
          "pricePerKwh": 0,
          "connectorTypes": ["Type 2"]
        },
        {
          "name": "Tesla Supercharger - Casablanca",
          "address": "Parking Onomo Hotel, Boulevard Al Massira Al Khadra, Casablanca 20250, Morocco",
          "latitude": 33.5731,
          "longitude": -7.5898,
          "available": true,
          "available_status": "Operational (Public - Tesla only)",
          "power": 120,
          "pricePerKwh": 0.25,
          "connectorTypes": ["Tesla Supercharger"]
        },
        {
          "name": "Porsche Destination Charging - Corniche By Palmeraie",
          "address": "90 Boulevard de la Corniche, Casablanca 20000, Morocco",
          "latitude": 33.6083,
          "longitude": -7.6349,
          "available": true,
          "available_status": null,
          "power": 22,
          "pricePerKwh": 0,
          "connectorTypes": ["Type 2"]
        },
        {
          "name": "FastVolt Afriquia Tafraouti",
          "address": "Avenue des FAR, Casablanca 20000, Morocco",
          "latitude": 33.5731,
          "longitude": -7.5898,
          "available": true,
          "available_status": null,
          "power": 50,
          "pricePerKwh": 2.5,
          "connectorTypes": ["Type 2", "CCS"]
        },
        {
          "name": "FastVolt Marjane Californie",
          "address": "Boulevard Panoramique, Casablanca 20150, Morocco",
          "latitude": 33.5731,
          "longitude": -7.5898,
          "available": true,
          "available_status": null,
          "power": 50,
          "pricePerKwh": 2.5,
          "connectorTypes": ["Type 2", "CCS"]
        },
        {
          "name": "Centre Porsche - Casablanca",
          "address": "Route de Nouaceur, Casablanca 20250, Morocco",
          "latitude": 33.5731,
          "longitude": -7.5898,
          "available": true,
          "available_status": null,
          "power": 22,
          "pricePerKwh": 0,
          "connectorTypes": ["Type 2"]
        },
        {
          "name": "FastVolt Parking Marina Shopping",
          "address": "Boulevard de la Corniche, Casablanca 20000, Morocco",
          "latitude": 33.6083,
          "longitude": -7.6349,
          "available": true,
          "available_status": null,
          "power": 50,
          "pricePerKwh": 2.5,
          "connectorTypes": ["Type 2", "CCS"]
        },
        {
          "name": "FastVolt - Afriquia El Jadida Centre Ville",
          "address": "El Jadida, Morocco",
          "latitude": 33.251,
          "longitude": -8.507,
          "available": true,
          "available_status": null,
          "power": 50,
          "pricePerKwh": 2.5,
          "connectorTypes": ["Type 2", "CCS"]
        },
        {
          "name": "TotalEnergies Relais Mazagan",
          "address": "Autoroute El Jadida Safi, Pk 25, El Jadida, Morocco",
          "latitude": 33.234,
          "longitude": -8.507,
          "available": true,
          "available_status": null,
          "power": 22,
          "pricePerKwh": 2.5,
          "connectorTypes": ["Type 2"]
        },
        {
          "name": "Royal El Jadida Golf",
          "address": "7H5G+PH6, 24000, El Jadida, Morocco",
          "latitude": 33.252,
          "longitude": -8.507,
          "available": true,
          "available_status": null,
          "power": 22,
          "pricePerKwh": 2.5,
          "connectorTypes": ["Type 2"]
        },
        {
          "name": "Tesla Supercharger - Agadir",
          "address": "Baie des Palmiers - Cité Founty P5, Agadir 80010, Morocco",
          "latitude": 30.427,
          "longitude": -9.598,
          "available": true,
          "available_status": "Operational (Public - Tesla only)",
          "power": 120,
          "pricePerKwh": 0.25,
          "connectorTypes": ["Tesla Supercharger"]
        },
        {
          "name": "FastVolt - Afriquia Agadir Centre Ville",
          "address": "CF48+H75, Agadir 80000, Morocco",
          "latitude": 30.427,
          "longitude": -9.598,
          "available": true,
          "available_status": null,
          "power": 50,
          "pricePerKwh": 2.5,
          "connectorTypes": ["Type 2", "CCS"]
        },
        {
          "name": "Parking Mairie Agadir - Kilowatt.ma",
          "address": "CC92+QMX, Agadir 80000, Morocco",
          "latitude": 30.427,
          "longitude": -9.598,
          "available": true,
          "available_status": null,
          "power": 22,
          "pricePerKwh": 2.5,
          "connectorTypes": ["Type 2"]
        },
        {
          "name": "Station-service Total Relais Agadir",
          "address": "Avenue El Moune, Agadir 80000, Morocco",
          "latitude": 30.427,
          "longitude": -9.598,
          "available": true,
          "available_status": null,
          "power": 22,
          "pricePerKwh": 2.5,
          "connectorTypes": ["Type 2"]
        },
        {
          "name": "FastVolt Afriquia Tétouan Park",
          "address": "Tétouan, Morocco",
          "latitude": 35.564015,
          "longitude": -5.486566,
          "available": true,
          "available_status": null,
          "power": 50,
          "pricePerKwh": 2.5,
          "connectorTypes": ["Type 2", "CCS"]
        },
        {
          "name": "IKEA Cabo Negro",
          "address": "90070 Cabo Negro, Morocco",
          "latitude": 35.5600,
          "longitude": -5.3000,
          "available": true,
          "available_status": null,
          "power": 22,
          "pricePerKwh": 2.5,
          "connectorTypes": ["Type 2"]
        },
        {
          "name": "Shell Meloussa",
          "address": "A4 94053 Meloussa, Morocco",
          "latitude": 35.6000,
          "longitude": -5.2500,
          "available": true,
          "available_status": null,
          "power": 22,
          "pricePerKwh": 2.5,
          "connectorTypes": ["Type 2"]
        },
        {
          "name": "Station Service Total Tanger MED",
          "address": "A4 Autoroute 90000 Ghedir, Morocco",
          "latitude": 35.7000,
          "longitude": -5.9167,
          "available": true,
          "available_status": null,
          "power": 22,
          "pricePerKwh": 2.5,
          "connectorTypes": ["Type 2"]
        },
        {
          "name": "Carrefour Salé EV Charging Station",
          "address": "Carrefour Market, Avenue Mohammed V, Salé, Morocco",
          "latitude": 34.0506,
          "longitude": -6.7823,
          "available": true,
          "available_status": null,
          "power": 22,
          "pricePerKwh": 2.5,
          "connectorTypes": ["Type 2"]
        },
        {
          "name": "TotalEnergies Tamesna Charging Station",
          "address": "Route de Tamesna, Salé, Morocco",
          "latitude": 34.0500,
          "longitude": -6.8000,
          "available": true,
          "available_status": null,
          "power": 22,
          "pricePerKwh": 2.5,
          "connectorTypes": ["Type 2"]
        }
      ];

      // Add each demo station to the batch
      for (final station in demoStations) {
        final docRef = stationsRef.doc();
        batch.set(docRef, {
          ...station,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Commit the batch
      await batch.commit();
      print('Demo stations initialized successfully');
    } catch (e) {
      print('Error initializing demo stations: $e');
      throw 'Failed to initialize demo stations';
    }
  }

  // Get nearby stations within a radius (in kilometers)
  Future<List<Map<String, dynamic>>> getNearbyStations(
    double latitude,
    double longitude, {
    double radius = 10,
  }) async {
    try {
      // Convert radius from km to degrees (approximate)
      final double latDegree = radius / 111.0; // 1 degree ≈ 111km
      final double lonDegree = radius / (111.0 * cos(latitude * pi / 180.0));

      final snapshot = await _firestore
          .collection('stations')
          .where('latitude', isGreaterThanOrEqualTo: latitude - latDegree)
          .where('latitude', isLessThanOrEqualTo: latitude + latDegree)
          .get();

      // Filter stations within longitude range and calculate actual distance
      final stations = snapshot.docs.where((doc) {
        final stationData = doc.data();
        final stationLat = stationData['latitude'] as double;
        final stationLon = stationData['longitude'] as double;

        // Check longitude range
        if (stationLon < longitude - lonDegree || stationLon > longitude + lonDegree) {
          return false;
        }

        // Calculate actual distance using Haversine formula
        final distance = _calculateDistance(
          latitude,
          longitude,
          stationLat,
          stationLon,
        );

        return distance <= radius;
      }).map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      return stations;
    } catch (e) {
      print('Error getting nearby stations: $e');
      return [];
    }
  }

  // Calculate distance between two points using Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }
}
