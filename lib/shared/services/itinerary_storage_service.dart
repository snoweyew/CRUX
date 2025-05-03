import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../../modules/itinerary_personalization/itinerary_model.dart';

class ItineraryStorageService {
  static const String _savedItinerariesKey = 'saved_itineraries';
  
  // Save an itinerary to local storage
  Future<bool> saveItinerary(ItineraryModel itinerary) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing saved itineraries
      final List<ItineraryModel> savedItineraries = await getSavedItineraries();
      
      // Check if an itinerary with the same location already exists
      final existingIndex = savedItineraries.indexWhere((item) => item.location == itinerary.location);
      
      if (existingIndex >= 0) {
        // Update existing itinerary
        savedItineraries[existingIndex] = itinerary;
      } else {
        // Add new itinerary
        savedItineraries.add(itinerary);
      }
      
      // Convert to list of JSON strings
      final List<String> itineraryJsonList = 
          savedItineraries.map((item) => jsonEncode(item.toJson())).toList();
      
      // Save to SharedPreferences
      return await prefs.setStringList(_savedItinerariesKey, itineraryJsonList);
    } catch (e) {
      print('Error saving itinerary: $e');
      return false;
    }
  }
  
  // Get all saved itineraries
  Future<List<ItineraryModel>> getSavedItineraries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? itineraryJsonList = prefs.getStringList(_savedItinerariesKey);
      
      if (itineraryJsonList == null || itineraryJsonList.isEmpty) {
        return [];
      }
      
      // Convert JSON strings to ItineraryModel objects
      return itineraryJsonList
          .map((jsonStr) => ItineraryModel.fromJson(jsonDecode(jsonStr)))
          .toList();
    } catch (e) {
      print('Error getting saved itineraries: $e');
      return [];
    }
  }
  
  // Check if there are any saved itineraries
  Future<bool> hasSavedItineraries() async {
    try {
      final itineraries = await getSavedItineraries();
      return itineraries.isNotEmpty;
    } catch (e) {
      print('Error checking saved itineraries: $e');
      return false;
    }
  }
  
  // Delete a saved itinerary
  Future<bool> deleteItinerary(String itineraryLocation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing saved itineraries
      final List<ItineraryModel> savedItineraries = await getSavedItineraries();
      
      // Filter out the itinerary to delete
      final updatedItineraries = 
          savedItineraries.where((item) => item.location != itineraryLocation).toList();
      
      // Convert to list of JSON strings
      final List<String> itineraryJsonList = 
          updatedItineraries.map((item) => jsonEncode(item.toJson())).toList();
      
      // Save updated list to SharedPreferences
      return await prefs.setStringList(_savedItinerariesKey, itineraryJsonList);
    } catch (e) {
      print('Error deleting itinerary: $e');
      return false;
    }
  }
  
  // Clear all saved itineraries
  Future<bool> clearAllItineraries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_savedItinerariesKey);
    } catch (e) {
      print('Error clearing itineraries: $e');
      return false;
    }
  }
}