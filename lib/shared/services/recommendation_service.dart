import 'dart:convert';
import 'package:flutter/material.dart'; // Import for TimeOfDay
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import '../config/app_config.dart';
import '../models/local_submission_model.dart'; // Keep this import
import '../models/product_model.dart'; // Import Product model

/// Service class to handle all recommendation-related API calls
/// Fetches approved recommendations, events, and products from Supabase.
class RecommendationService {
  final String baseUrl;
  final String apiKey;
  final SupabaseClient _supabase; // Add Supabase client instance

  RecommendationService({
    String? baseUrl,
    String? apiKey,
    SupabaseClient? supabase, // Allow injecting Supabase client
  }) : baseUrl = baseUrl ?? AppConfig.apiUrl,
       apiKey = apiKey ?? AppConfig.apiKey,
       _supabase = supabase ?? Supabase.instance.client; // Initialize Supabase client

  /// Generic method to fetch recommendations from Supabase tables
  /// based on the category.
  Future<List<Map<String, String>>> fetchRecommendations(String category, {String? city}) async {
    try {
      String tableName;
      String selectColumns = '*'; // Default select all
      Map<String, dynamic> filters = {};

      // Determine table and filters based on category
      switch (category.toLowerCase()) {
        case 'food':
        case 'experience':
        case 'attraction':
          tableName = 'local_submissions';
          filters['status'] = SubmissionStatus.approved.name;
          filters['category'] = category.toLowerCase();
          // Add city filter if applicable and column exists
          // if (city != null && city.isNotEmpty) filters['city'] = city;
          break;
        case 'events':
          tableName = 'events';
          // Add filters if needed, e.g., filter by upcoming events
          // filters['status'] = 'Upcoming';
          // Add city filter if applicable and column exists
          // if (city != null && city.isNotEmpty) filters['city'] = city;
          break;
        case 'shopping': // This category maps to the 'products' table
          tableName = 'products';
          // Add city filter if applicable and column exists
          // if (city != null && city.isNotEmpty) filters['city'] = city;
          break;
        default:
          print('Unknown recommendation category: $category');
          return [];
      }

      // Build the query
      var query = _supabase.from(tableName).select(selectColumns);
      filters.forEach((key, value) {
        query = query.eq(key, value);
      });

      final response = await query;

      // Map the response to the expected format List<Map<String, String>>
      // Ensure all values are explicitly converted to String
      final recommendations = (response as List).map((item) {
        // Map data based on the source table (category)
        switch (category.toLowerCase()) {
          case 'food':
          case 'experience':
          case 'attraction':
            final submission = LocalSubmission.fromJson(item);
            return <String, String>{ // Explicitly type the map
              'id': submission.id,
              'name': submission.name,
              'description': submission.description,
              'location': submission.location,
              'imageUrl': submission.photoUrl ?? '',
              'category': submission.category,
              'latitude': submission.latitude.toString(),
              'longitude': submission.longitude.toString(),
              'start_time': '${submission.startTime.hour}:${submission.startTime.minute.toString().padLeft(2, '0')}',
              'end_time': '${submission.endTime.hour}:${submission.endTime.minute.toString().padLeft(2, '0')}',
            };
          case 'events':
            DateTime? startDate = DateTime.tryParse(item['start_date']?.toString() ?? '');
            DateTime? endDate = DateTime.tryParse(item['end_date']?.toString() ?? '');
            return <String, String>{ // Explicitly type the map
              'id': item['id']?.toString() ?? '',
              'name': item['title']?.toString() ?? 'No Title',
              'description': item['description']?.toString() ?? '',
              'location': item['venue']?.toString() ?? '',
              'imageUrl': item['image_url']?.toString() ?? '',
              'category': item['category']?.toString() ?? 'event',
              'startDate': startDate?.toIso8601String() ?? '',
              'endDate': endDate?.toIso8601String() ?? '',
              'status': item['status']?.toString() ?? '',
              'city': item['city']?.toString() ?? '',
            };
          case 'shopping':
            final product = Product.fromJson(item);
            return <String, String>{ // Explicitly type the map
              'id': product.id,
              'name': product.name,
              'description': product.description,
              'location': product.location, // Vendor/Shop
              'price': product.price.toStringAsFixed(2), // Format price
              'imageUrl': product.imageUrl ?? '',
              'category': product.category,
              'city': product.city ?? '',
            };
          default:
            return <String, String>{}; // Should not happen
        }
      }).toList(); // This now correctly produces List<Map<String, String>>

      return recommendations;

    } catch (e) {
      print('Error fetching $category recommendations from Supabase: $e');
      // Return empty list or rethrow depending on desired error handling
      return [];
      // throw Exception('Error fetching $category recommendations: $e');
    }
  }

  // --- Keep existing specific methods if they are still used elsewhere, ---
  // --- but they should ideally call the updated fetchRecommendations ---
  // --- or be removed if fetchRecommendations covers all cases. ---

  /// Events recommendations
  Future<List<Map<String, String>>> getEvents({String? city}) async {
    // Pass city to fetchRecommendations
    return fetchRecommendations('events', city: city);
  }

  /// Food recommendations
  Future<List<Map<String, String>>> getFood({String? city}) async {
    // Pass city to fetchRecommendations
    return fetchRecommendations('food', city: city);
  }

  /// Experiences recommendations
  Future<List<Map<String, String>>> getExperiences({String? city}) async {
    // Pass city to fetchRecommendations
    return fetchRecommendations('experience', city: city); // Assuming 'experience' is the category key
  }

  /// Attractions recommendations
  Future<List<Map<String, String>>> getAttractions({String? city}) async {
    // Pass city to fetchRecommendations
    return fetchRecommendations('attraction', city: city); // Assuming 'attraction' is the category key
  }

  /// Shopping recommendations
  /// NOTE: local_submissions might not have 'price'. Adjust mapping if needed.
  Future<List<Map<String, String>>> getShopping({String? city}) async {
    // Pass city to fetchRecommendations
    return fetchRecommendations('shopping', city: city); // Assuming 'shopping' is a category
  }


  // Mock data implementation - MODIFIED to accept city and include image URLs
  // Backend Note: This mock data structure shows the minimum required fields
  // and format for each category. Your API should return data in a similar structure.
  // If using API, the backend needs to support filtering by city.
  List<Map<String, String>> getMockRecommendations(String category, {String? city}) {
    // --- Placeholder Mock Data Structure (Includes city and image URLs) ---
    final allMockData = {
      'Kuching': {
        'events': [
           {'name': 'Rainforest Music Festival (Kuching)', 'description': 'Annual world music festival', 'location': 'Sarawak Cultural Village', 'imageUrl': 'https://images.pexels.com/photos/1190297/pexels-photo-1190297.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1'},
           {'name': 'Kuching Food Festival', 'description': 'Showcasing local cuisine', 'location': 'Kuching Waterfront', 'imageUrl': 'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1'}
        ],
        'food': [
           {'name': 'Sarawak Laksa (Kuching)', 'description': 'Famous local noodle dish', 'location': 'Central Market Food Court', 'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/88/Laksa_Sarawak.jpg/1200px-Laksa_Sarawak.jpg'},
           {'name': 'Kolo Mee (Kuching)', 'description': 'Traditional dry noodle dish', 'location': 'Open Air Market', 'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e3/Kolo_Mee_at_Choon_Hui_Cafe%2C_Kuching%2C_Sarawak%2C_Malaysia.jpg/1024px-Kolo_Mee_at_Choon_Hui_Cafe%2C_Kuching%2C_Sarawak%2C_Malaysia.jpg'}
        ],
        'experiences': [
           {'name': 'Semenggoh Wildlife Centre (Kuching)', 'description': 'Watch orangutans', 'location': 'Semenggoh', 'imageUrl': 'https://images.pexels.com/photos/207838/pexels-photo-207838.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1'},
           {'name': 'River Cruise (Kuching)', 'description': 'Evening cruise', 'location': 'Kuching Waterfront', 'imageUrl': 'https://images.pexels.com/photos/3889854/pexels-photo-3889854.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1'}
        ],
        'attractions': [
           {'name': 'Kuching Waterfront', 'description': 'Scenic riverside promenade', 'location': 'City Center', 'imageUrl': 'https://images.pexels.com/photos/4542639/pexels-photo-4542639.jpeg'},
           {'name': 'Sarawak Cultural Village (Kuching)', 'description': 'Living museum', 'location': 'Damai Beach', 'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a4/Sarawak_Cultural_Village_-_Iban_Longhouse.jpg/1280px-Sarawak_Cultural_Village_-_Iban_Longhouse.jpg'}
        ],
        'shopping': [ // Updated Shopping Data
          {
            'id': 'sh_001',
            'name': 'Pua Kumbu Print Scarf',
            'location': 'Sarawak Handicraft',
            'price': '85.00',
            'imageUrl': 'https://sarawakhandicraft.com.my/wp-content/uploads/2023/07/WhatsApp-Image-2023-07-18-at-11.46.00-AM-1-400x400.jpeg'
          },
          {
            'id': 'sh_002',
            'name': 'Beaded Necklace (Orang Ulu)',
            'location': 'Sarawak Handicraft',
            'price': '120.00',
            'imageUrl': 'https://sarawakhandicraft.com.my/wp-content/uploads/2023/07/WhatsApp-Image-2023-07-18-at-11.46.00-AM-400x400.jpeg'
          },
          {
            'id': 'sh_003',
            'name': 'Rattan Basket Bag',
            'location': 'Sarawak Handicraft',
            'price': '150.00',
            'imageUrl': 'https://sarawakhandicraft.com.my/wp-content/uploads/2023/07/WhatsApp-Image-2023-07-18-at-11.45.59-AM-1-400x400.jpeg'
          },
          {
            'id': 'sh_004',
            'name': 'Wooden Tribal Mask',
            'location': 'Sarawak Handicraft',
            'price': '250.00',
            'imageUrl': 'https://sarawakhandicraft.com.my/wp-content/uploads/2023/07/WhatsApp-Image-2023-07-18-at-11.45.58-AM-400x400.jpeg'
          },
          {
            'id': 'sh_005',
            'name': 'Sarawak Pottery Vase',
            'location': 'Sarawak Handicraft',
            'price': '95.00',
            'imageUrl': 'https://sarawakhandicraft.com.my/wp-content/uploads/2023/07/WhatsApp-Image-2023-07-18-at-11.45.57-AM-1-400x400.jpeg'
          },
          {
            'id': 'sh_006',
            'name': 'Blowpipe with Darts',
            'location': 'Sarawak Handicraft',
            'price': '180.00',
            'imageUrl': 'https://sarawakhandicraft.com.my/wp-content/uploads/2023/07/WhatsApp-Image-2023-07-18-at-11.45.57-AM-400x400.jpeg'
          },
          {
            'id': 'sh_007',
            'name': 'Hand Woven Coasters (Set of 6)',
            'location': 'Sarawak Handicraft',
            'price': '45.00',
            'imageUrl': 'https://sarawakhandicraft.com.my/wp-content/uploads/2023/07/WhatsApp-Image-2023-07-18-at-11.45.56-AM-1-400x400.jpeg'
          },
          {
            'id': 'sh_008',
            'name': 'Iban Shield Replica',
            'location': 'Sarawak Handicraft',
            'price': '350.00',
            'imageUrl': 'https://sarawakhandicraft.com.my/wp-content/uploads/2023/07/WhatsApp-Image-2023-07-18-at-11.45.56-AM-400x400.jpeg'
          },
          {
            'id': 'sh_009',
            'name': 'Bidayuh Bamboo Pen Holder',
            'location': 'Sarawak Handicraft',
            'price': '35.00',
            'imageUrl': 'https://sarawakhandicraft.com.my/wp-content/uploads/2023/07/WhatsApp-Image-2023-07-18-at-11.45.55-AM-1-400x400.jpeg'
          },
          {
            'id': 'sh_010',
            'name': 'Sape Instrument Miniature',
            'location': 'Sarawak Handicraft',
            'price': '190.00',
            'imageUrl': 'https://sarawakhandicraft.com.my/wp-content/uploads/2023/07/WhatsApp-Image-2023-07-18-at-11.45.55-AM-400x400.jpeg'
          }
        ]
      },
      'Miri': {
         'events': [
            {'name': 'Borneo Jazz Festival (Miri)', 'description': 'International jazz event', 'location': 'Coco Cabana Miri', 'imageUrl': 'https://images.pexels.com/photos/1105666/pexels-photo-1105666.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1'}
         ],
         'food': [
            {'name': 'Miri Seafood', 'description': 'Fresh catches from the sea', 'location': 'Tanjong Lobang', 'imageUrl': 'https://images.pexels.com/photos/1482803/pexels-photo-1482803.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1'},
            {'name': 'Nasi Lemak (Miri)', 'description': 'Popular Malaysian dish', 'location': 'Various stalls', 'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/ba/Nasi_Lemak_served_in_Kuala_Lumpur.jpg/1280px-Nasi_Lemak_served_in_Kuala_Lumpur.jpg'}
         ],
         'experiences': [
            {'name': 'Diving at Miri-Sibuti Coral Reef', 'description': 'Explore underwater life', 'location': 'Offshore Miri', 'imageUrl': 'https://images.pexels.com/photos/167695/pexels-photo-167695.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1'},
            {'name': 'Niah Caves Exploration (Near Miri)', 'description': 'Visit ancient caves', 'location': 'Niah National Park', 'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/13/Niah_Cave_Great_Cave_mouth.jpg/1280px-Niah_Cave_Great_Cave_mouth.jpg'}
         ],
         'attractions': [
            {'name': 'Canada Hill (Miri)', 'description': 'Viewpoint and historical site', 'location': 'Miri City', 'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e9/Canada_Hill%2C_Miri%2C_Sarawak%2C_Malaysia.jpg/1280px-Canada_Hill%2C_Miri%2C_Sarawak%2C_Malaysia.jpg'},
            {'name': 'Tusan Beach (Miri)', 'description': 'Cliffs and "blue tears" phenomenon', 'location': 'Near Bekenu', 'imageUrl': 'https://images.pexels.com/photos/22776427/pexels-photo-22776427/free-photo-of-boats-on-beach-in-summer.jpeg'}
         ],
         'shopping': [
            {'id': 'miri_craft1', 'name': 'Local Handicrafts (Miri)', 'location': 'Miri Handicraft Centre', 'price': '50.00', 'imageUrl': 'https://images.pexels.com/photos/1090638/pexels-photo-1090638.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1'}
         ]
      },
      'Sibu': {
        'food': [{'name': 'Sibu Kampua Mee', 'description': 'Iconic Sibu noodle dish', 'location': 'Sibu Central Market', 'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c3/Kampua_mee_sibu.jpg/1024px-Kampua_mee_sibu.jpg'}]
      },
      'Bintulu': {
        'attractions': [{'name': 'Similajau National Park (Bintulu)', 'description': 'Coastal park', 'location': 'Near Bintulu', 'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a9/Similajau_National_Park_Sarawak_Malaysia_Turtle_Beach_1.jpg/1280px-Similajau_National_Park_Sarawak_Malaysia_Turtle_Beach_1.jpg'}]
      }
      // Add more cities and data as needed
    };
    // --- End Placeholder Mock Data ---

    final categoryLower = category.toLowerCase();

    // If city is provided, filter by city first
    if (city != null && city.isNotEmpty) {
      return allMockData[city]?[categoryLower] ?? [];
    }

    // Fallback: If no city provided, return data for the category from all cities (or just the first city as before? Let's stick to the new logic: return empty if no city)
    // Original fallback was just returning the category data without city filter.
    // Returning empty list if no city is specified seems more consistent with the requirement.
    return [];

    /* // Original logic (kept for reference, now replaced by city filtering)
    switch (category.toLowerCase()) {
      case 'events':
        return [...]; // Original event data
      case 'food':
        return [...]; // Original food data
      // ... etc for other categories ...
      default:
        return [];
    }
    */
  }
}