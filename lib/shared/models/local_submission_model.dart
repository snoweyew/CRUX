import 'package:flutter/material.dart';

enum SubmissionStatus {
  pending,
  approved,
  rejected
}

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

  factory LocalSubmission.fromJson(Map<String, dynamic> json) {
    final startTimeParts = (json['start_time'] as String).split(':');
    final endTimeParts = (json['end_time'] as String).split(':');

    return LocalSubmission(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      location: json['location'],
      category: json['category'],
      description: json['description'],
      photoUrl: json['photo_url'],
      submittedAt: DateTime.parse(json['submitted_at']),
      latitude: json['latitude'],
      longitude: json['longitude'],
      startTime: TimeOfDay(
        hour: int.parse(startTimeParts[0]),
        minute: int.parse(startTimeParts[1]),
      ),
      endTime: TimeOfDay(
        hour: int.parse(endTimeParts[0]),
        minute: int.parse(startTimeParts[1]),
      ),
      status: SubmissionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => SubmissionStatus.pending,
      ),
      rejectionReason: json['rejection_reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'location': location,
      'category': category,
      'description': description,
      'photo_url': photoUrl,
      'submitted_at': submittedAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'start_time': '${startTime.hour}:${startTime.minute}',
      'end_time': '${endTime.hour}:${endTime.minute}',
      'status': status.toString().split('.').last,
      'rejection_reason': rejectionReason,
    };
  }
} 