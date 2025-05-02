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

  // Get all submissions with a specific status (e.g., 'pending')
  Future<List<LocalSubmission>> getSubmissionsByStatus(SubmissionStatus status) async {
    // Note: STB users might need different RLS policies in Supabase
    // to access all submissions.
    try {
      final response = await _supabase
          .from('local_submissions')
          .select()
          .eq('status', status.toString().split('.').last) // Filter by status string
          .order('submitted_at', ascending: true); // Show oldest first

      return (response as List)
          .map((json) => LocalSubmission.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting submissions by status: $e');
      rethrow;
    }
  }

  // Update the status of a submission (for STB approval/rejection)
  Future<LocalSubmission> updateSubmissionStatus({
    required String submissionId,
    required SubmissionStatus status,
    String? rejectionReason,
  }) async {
    // Ensure the user performing this action has the necessary permissions (e.g., STB role)
    // This might involve checking user metadata or roles, potentially fetched during login.
    // For simplicity, we'll assume the logged-in user has permission.
    final currentUser = _supabase.auth.currentUser;
     if (currentUser == null) {
       throw Exception('Not authenticated with Supabase');
     }
     // Add role check here if implemented, e.g.:
     // if (currentUser.userMetadata?['role'] != 'stb_staff') {
     //   throw Exception('User does not have permission to update status');
     // }

    try {
      final updateData = {
        'status': status.toString().split('.').last,
        'rejection_reason': status == SubmissionStatus.rejected ? rejectionReason : null,
        // Optionally update an 'approved_by' or 'reviewed_at' field
      };

      final response = await _supabase
          .from('local_submissions')
          .update(updateData)
          .eq('id', submissionId)
          .select()
          .single();

      return LocalSubmission.fromJson(response);
    } catch (e) {
      print('Error updating submission status: $e');
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

  // Save or update user profile details (name, location)
  Future<void> saveUserProfile(String name, String location) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('Not authenticated with Supabase');
    }

    try {
      // Assuming a 'profiles' table linked to auth.users via 'id'
      await _supabase.from('profiles').upsert({
        'id': currentUser.id, // Primary key, same as auth user ID
        'name': name,
        'location': location, // Origin city/country/state
        'updated_at': DateTime.now().toIso8601String(),
      });
      print('User profile saved/updated in Supabase for user: ${currentUser.id}');
    } catch (e) {
      print('Error saving user profile to Supabase: $e');
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