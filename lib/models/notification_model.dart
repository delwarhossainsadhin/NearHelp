
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool read;
  final String type;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.read,
    this.type = 'general',
  });

  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime parsedTime;
    final rawTime = map['timestamp'];
    if (rawTime is Timestamp) {
      parsedTime = rawTime.toDate();
    } else if (rawTime is String) {
      parsedTime = DateTime.tryParse(rawTime) ?? DateTime.now();
    } else {
      parsedTime = DateTime.now();
    }

    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      timestamp: parsedTime,
      read: map['read'] ?? false,
      type: map['type'] ?? 'general',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'timestamp': timestamp,
      'read': read,
      'type': type,
    };
  }
}