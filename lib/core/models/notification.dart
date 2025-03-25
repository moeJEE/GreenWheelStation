class EVNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String type;
  final bool isRead;
  final String? imageUrl;

  EVNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.imageUrl,
  });

  factory EVNotification.fromJson(Map<String, dynamic> json) {
    return EVNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: json['type'] as String,
      isRead: json['isRead'] as bool? ?? false,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'isRead': isRead,
      'imageUrl': imageUrl,
    };
  }
}
