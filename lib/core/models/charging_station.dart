class ChargingStation {
  final String name;
  final String location;
  final bool available;
  final String distance;
  final String openingTime;
  final String closingTime;
  final String completeAddress;
  final String chargeType;
  final List<String> images;
  final double latitude;
  final double longitude;

  ChargingStation({
    required this.name,
    required this.location,
    required this.available,
    required this.distance,
    required this.openingTime,
    required this.closingTime,
    required this.completeAddress,
    required this.chargeType,
    required this.images,
    required this.latitude,
    required this.longitude,
  });

  factory ChargingStation.fromJson(Map<String, dynamic> json) {
    return ChargingStation(
      name: json['name'],
      location: json['location'],
      available: json['available'],
      distance: json['distance'],
      openingTime: json['openingTime'],
      closingTime: json['closingTime'],
      completeAddress: json['completeAddress'],
      chargeType: json['chargeType'],
      images: List<String>.from(json['images']),
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'location': location,
      'available': available,
      'distance': distance,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'completeAddress': completeAddress,
      'chargeType': chargeType,
      'images': images,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
