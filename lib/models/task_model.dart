import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String taskId;
  final String customerId;
  final String customerName;
  final String title;
  final String description;
  final String category;
  final double budget;
  final String location;
  final String? imageUrl;
  final String status;
  final String? acceptedBy;
  final String paymentStatus;
  String? transactionId;
  final DateTime createdAt;

  TaskModel({
    required this.taskId,
    required this.customerId,
    required this.customerName,
    required this.title,
    required this.description,
    required this.category,
    required this.budget,
    required this.location,
    this.imageUrl,
    this.status = 'open',
    this.acceptedBy,
    this.paymentStatus = 'unpaid',
    this.transactionId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'customerId': customerId,
      'customerName': customerName,
      'title': title,
      'description': description,
      'category': category,
      'budget': budget,
      'location': location,
      'imageUrl': imageUrl,
      'status': status,
      'acceptedBy': acceptedBy,
      'paymentStatus': paymentStatus,
      'transactionId': transactionId,
      'createdAt': createdAt,
    };
  }


  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      taskId: map['taskId'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      budget: (map['budget'] ?? 0).toDouble(),
      location: map['location'] ?? '',
      imageUrl: map['imageUrl'],
      status: map['status'] ?? 'open',
      acceptedBy: map['acceptedBy'],
      paymentStatus: map['paymentStatus'] ?? 'unpaid',
      transactionId: map['transactionId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}