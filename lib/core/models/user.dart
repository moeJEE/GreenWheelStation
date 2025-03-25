import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String? userId;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? brand;
  final String? model;
  final List<String>? favoriteStations;
  final Timestamp? createdAt;

  User({
    this.userId,
    this.firstName,
    this.lastName,
    this.email,
    this.brand,
    this.model,
    this.favoriteStations,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      brand: json['brand'],
      model: json['model'],
      favoriteStations: json['favoriteStations'] != null 
          ? List<String>.from(json['favoriteStations'])
          : null,
      createdAt: json['createdAt'] is Timestamp 
          ? json['createdAt'] 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'brand': brand,
      'model': model,
      'favoriteStations': favoriteStations,
      'createdAt': createdAt,
    };
  }
}
