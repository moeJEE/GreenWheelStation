class Station {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final bool available;
  final String? availableStatus;
  final double power;
  final double pricePerKwh;
  final List<String> connectorTypes;
  final bool isDemoStation;

  Station({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.available,
    required this.availableStatus,
    required this.power,
    required this.pricePerKwh,
    required this.connectorTypes,
    this.isDemoStation = false,
  });

  factory Station.fromJson(String id, Map<String, dynamic> json) {
    return Station(
      id: id,
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      available: json['available'] as bool,
      availableStatus: json['available_status'] as String?,
      power: (json['power'] as num).toDouble(),
      pricePerKwh: (json['pricePerKwh'] as num).toDouble(),
      connectorTypes: List<String>.from(json['connectorTypes'] as List),
      isDemoStation: json['isDemoStation'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'available': available,
      'available_status': available,
      'power': power,
      'pricePerKwh': pricePerKwh,
      'connectorTypes': connectorTypes,
      'isDemoStation': isDemoStation,
    };
  }
}
