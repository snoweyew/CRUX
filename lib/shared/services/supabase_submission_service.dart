import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../models/local_submission_model.dart';
import '../models/user_model.dart';

class SupabaseSubmissionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Create a new submission
  Future<LocalSubmission> createSubmission({
    required UserModel user,
    required String name,
    required String location,
    required String category,
    required String description,
    required String photoUrl,
    required double latitude,
    required double longitude,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  }) async {
    final currentUser = _supabase.auth.currentUser;
    print('Current Supabase user: ${currentUser?.id}');
    if (currentUser == null) {
      throw Exception('Not authenticated with Supabase');
    }

    try {
      final response = await _supabase
          .from('local_submissions')
          .insert({
            'user_id': currentUser.id,
            'name': name,
            'location': location,
            'category': category,
            'description': description,
            'photo_url': photoUrl,
            'latitude': latitude,
            'longitude': longitude,
            'start_time': '${startTime.hour}:${startTime.minute}',
            'end_time': '${endTime.hour}:${endTime.minute}',
          })
          .select()
          .single();

      return LocalSubmission.fromJson(response);
    } catch (e) {
      print('Error creating submission: $e');
      rethrow;
    }
  }

  // Get all submissions for a user
  Future<List<LocalSubmission>> getUserSubmissions(String userId) async {
    final currentUser = _supabase.auth.currentUser;
    print('Current Supabase user: ${currentUser?.id}');
    if (currentUser == null) {
      throw Exception('Not authenticated with Supabase');
    }

    try {
      final response = await _supabase
          .from('local_submissions')
          .select()
          .eq('user_id', currentUser.id)
          .order('submitted_at', ascending: false);

      return (response as List)
          .map((json) => LocalSubmission.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting submissions: $e');
      rethrow;
    }
  }

  // Update a submission
  Future<LocalSubmission> updateSubmission({
    required String submissionId,
    required String name,
    required String location,
    required String category,
    required String description,
    required String photoUrl,
    required double latitude,
    required double longitude,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  }) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('Not authenticated with Supabase');
    }

    try {
      final response = await _supabase
          .from('local_submissions')
          .update({
            'name': name,
            'location': location,
            'category': category,
            'description': description,
            'photo_url': photoUrl,
            'latitude': latitude,
            'longitude': longitude,
            'start_time': '${startTime.hour}:${startTime.minute}',
            'end_time': '${endTime.hour}:${endTime.minute}',
          })
          .eq('id', submissionId)
          .eq('user_id', currentUser.id) // Ensure user can only update their own submissions
          .select()
          .single();

      return LocalSubmission.fromJson(response);
    } catch (e) {
      print('Error updating submission: $e');
      rethrow;
    }
  }

  // Delete a submission
  Future<void> deleteSubmission(String submissionId) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('Not authenticated with Supabase');
    }

    try {
      await _supabase
          .from('local_submissions')
          .delete()
          .eq('id', submissionId)
          .eq('user_id', currentUser.id); // Ensure user can only delete their own submissions
    } catch (e) {
      print('Error deleting submission: $e');
      rethrow;
    }
  }

  // Upload photo to Supabase Storage
  Future<String> uploadPhoto(String filePath) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('Not authenticated with Supabase');
    }

    try {
      final file = File(filePath);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final folderPath = '${currentUser.id}/$fileName';

      await _supabase.storage
          .from('submission_photos')
          .upload(folderPath, file);

      return _supabase.storage
          .from('submission_photos')
          .getPublicUrl(folderPath);
    } catch (e) {
      print('Error uploading photo: $e');
      throw Exception('Failed to upload photo: $e');
    }
  }
}