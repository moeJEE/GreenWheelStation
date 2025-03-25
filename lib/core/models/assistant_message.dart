import 'package:cloud_firestore/cloud_firestore.dart';

class AssistantMessage {
  final String sender;
  final String message;
  final Timestamp createdAt;

  AssistantMessage({
    required this.sender,
    required this.message,
    required this.createdAt,
  });

  factory AssistantMessage.fromJson(Map<String, dynamic> json) {
    return AssistantMessage(
      sender: json['sender'] as String,
      message: json['message'] as String,
      createdAt: json['createdAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender': sender,
      'message': message,
      'createdAt': createdAt,
    };
  }
}
