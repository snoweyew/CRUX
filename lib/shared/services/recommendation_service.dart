import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Service class to handle all recommendation-related API calls
/// Backend API Implementation Guide:
/// 1. Base URL: https://kangaroo.management.azure-api.net
/// 2. All endpoints should be under /api/recommendations/
/// 3. Authentication: Use x-api-key header for API key authentication
/// 4. Response format should be JSON array of objects
class RecommendationService {
  final String baseUrl;
  final String apiKey;

  RecommendationService({
    String? baseUrl,
    String? apiKey,
  }) : baseUrl = baseUrl ?? AppConfig.apiUrl,
       apiKey = apiKey ?? AppConfig.apiKey;

  /// Generic method to fetch recommendations
  /// Backend Implementation Notes:
  /// - Each endpoint should return a list of items
  /// - Required fields for all items: name, description, location
  /// - Shopping items require additional fields: id, price
  /// - All text fields should be strings
  /// - Prices should be formatted as strings with 2 decimal places (e.g. "299.00")
  Future<List<Map<String, String>>> fetchRecommendations(String category) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/recommendations/$category'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Map<String, String>.from(item)).toList();
      } else {
        throw Exception('Failed to fetch $category recommendations');
      }
    } catch (e) {
      throw Exception('Error fetching $category recommendations: $e');
    }
  }

  /// Events recommendations
  /// Endpoint: GET /api/recommendations/events
  /// Required fields:
  /// - name: Name of the event
  /// - description: Brief description of the event
  /// - location: Where the event takes place
  /// Optional fields:
  /// - date: Event date in ISO format
  /// - time: Event time
  /// - price: Event ticket price if applicable
  Future<List<Map<String, String>>> getEvents() async {
    return fetchRecommendations('events');
  }

  /// Food recommendations
  /// Endpoint: GET /api/recommendations/food
  /// Required fields:
  /// - name: Name of the dish/restaurant
  /// - description: Description of the food
  /// - location: Restaurant/stall location
  /// Optional fields:
  /// - price: Average price or price range
  /// - cuisine: Type of cuisine
  /// - openingHours: Operating hours
  Future<List<Map<String, String>>> getFood() async {
    return fetchRecommendations('food');
  }

  /// Experiences recommendations
  /// Endpoint: GET /api/recommendations/experiences
  /// Required fields:
  /// - name: Name of the experience
  /// - description: What the experience entails
  /// - location: Where it takes place
  /// Optional fields:
  /// - duration: How long it takes
  /// - price: Cost per person
  /// - bookingRequired: Yes/No
  Future<List<Map<String, String>>> getExperiences() async {
    return fetchRecommendations('experiences');
  }

  /// Attractions recommendations
  /// Endpoint: GET /api/recommendations/attractions
  /// Required fields:
  /// - name: Name of the attraction
  /// - description: Description of what visitors can see/do
  /// - location: Address or area
  /// Optional fields:
  /// - openingHours: Operating hours
  /// - entranceFee: Admission fee if any
  /// - type: Type of attraction (museum, park, etc.)
  Future<List<Map<String, String>>> getAttractions() async {
    return fetchRecommendations('attractions');
  }

  /// Shopping recommendations
  /// Endpoint: GET /api/recommendations/shopping
  /// Required fields:
  /// - id: Unique identifier for the product
  /// - name: Product name
  /// - description: Product description
  /// - location: Where to buy
  /// - price: Price in RM (format: "0.00")
  /// Optional fields:
  /// - category: Product category
  /// - availability: Stock status
  /// - vendor: Seller/shop name
  Future<List<Map<String, String>>> getShopping() async {
    return fetchRecommendations('shopping');
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