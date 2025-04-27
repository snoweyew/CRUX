import 'package:flutter/material.dart';

class LocalSubmission {
  final String id;
  final String userId;
  final String name;
  final String location;
  final String category;
  final String description;
  final String? photoUrl;
  final DateTime submittedAt;
  final double latitude;
  final double longitude;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final SubmissionStatus status;
  final String? rejectionReason;

  LocalSubmission({
    required this.id,
    required this.userId,
    required this.name,
    required this.location,
    required this.category,
    required this.description,
    this.photoUrl,
    required this.submittedAt,
    required this.latitude,
    required this.longitude,
    required this.startTime,
    required this.endTime,
    this.status = SubmissionStatus.pending,
    this.rejectionReason,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'location': location,
      'category': category,
      'description': description,
      'photoUrl': photoUrl,
      'submittedAt': submittedAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'startTime': '${startTime.hour}:${startTime.minute}',
      'endTime': '${endTime.hour}:${endTime.minute}',
      'status': status.toString(),
      'rejectionReason': rejectionReason,
    };
  }

  factory LocalSubmission.fromJson(Map<String, dynamic> json) {
    final startTimeParts = (json['startTime'] as String).split(':');
    final endTimeParts = (json['endTime'] as String).split(':');

    return LocalSubmission(
      id: json['id'],
      userId: json['userId'],
      name: json['name'],
      location: json['location'],
      category: json['category'],
      description: json['description'],
      photoUrl: json['photoUrl'],
      submittedAt: DateTime.parse(json['submittedAt']),
      latitude: json['latitude'],
      longitude: json['longitude'],
      startTime: TimeOfDay(
        hour: int.parse(startTimeParts[0]),
        minute: int.parse(startTimeParts[1]),
      ),
      endTime: TimeOfDay(
        hour: int.parse(endTimeParts[0]),
        minute: int.parse(endTimeParts[1]),
      ),
      status: SubmissionStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => SubmissionStatus.pending,
      ),
      rejectionReason: json['rejectionReason'],
    );
  }
}

enum SubmissionStatus {
  pending,
  approved,
  rejected
} 