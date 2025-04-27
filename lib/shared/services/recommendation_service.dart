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

  // Mock data implementation for testing and fallback
  // Backend Note: This mock data structure shows the minimum required fields
  // and format for each category. Your API should return data in a similar structure.
  List<Map<String, String>> getMockRecommendations(String category) {
    switch (category.toLowerCase()) {
      case 'events':
        return [
          {
            'name': 'Rainforest Music Festival',
            'description': 'Annual world music festival featuring traditional and contemporary performances',
            'location': 'Sarawak Cultural Village'
          },
          {
            'name': 'Gawai Festival',
            'description': 'Traditional harvest festival celebrating Dayak culture',
            'location': 'Various locations'
          },
          {
            'name': 'Kuching Food Festival',
            'description': 'Annual food festival showcasing local cuisine',
            'location': 'Kuching Waterfront'
          }
        ];
      case 'food':
        return [
          {
            'name': 'Sarawak Laksa',
            'description': 'Famous local noodle dish with spicy coconut milk broth',
            'location': 'Central Market Food Court'
          },
          {
            'name': 'Kolo Mee',
            'description': 'Traditional dry noodle dish with minced meat',
            'location': 'Open Air Market'
          },
          {
            'name': 'Midin Belacan',
            'description': 'Local jungle fern stir-fried with shrimp paste',
            'location': 'Top Spot Food Court'
          }
        ];
      case 'experiences':
        return [
          {
            'name': 'Traditional Craft Workshop',
            'description': 'Learn to make traditional beaded crafts',
            'location': 'Main Bazaar'
          },
          {
            'name': 'Semenggoh Wildlife Centre',
            'description': 'Watch orangutans in their natural habitat',
            'location': 'Semenggoh'
          },
          {
            'name': 'River Cruise',
            'description': 'Evening cruise along the Sarawak River',
            'location': 'Kuching Waterfront'
          }
        ];
      case 'attractions':
        return [
          {
            'name': 'Kuching Waterfront',
            'description': 'Scenic riverside promenade with historic buildings',
            'location': 'City Center'
          },
          {
            'name': 'Sarawak Cultural Village',
            'description': 'Living museum showcasing local ethnic cultures',
            'location': 'Damai Beach'
          },
          {
            'name': 'Bako National Park',
            'description': 'Coastal park with diverse wildlife and hiking trails',
            'location': 'Bako'
          }
        ];
      case 'shopping':
        return [
          {
            'id': 'craft1',
            'name': 'Traditional Pua Kumbu Textile',
            'description': 'Hand-woven ceremonial blanket with intricate patterns',
            'location': 'Main Bazaar',
            'price': '299.00'
          },
          {
            'id': 'craft2',
            'name': 'Orang Ulu Beaded Necklace',
            'description': 'Handcrafted beaded jewelry with traditional motifs',
            'location': 'Kuching Old Town',
            'price': '89.00'
          },
          {
            'id': 'craft3',
            'name': 'Bidayuh Bamboo Basket',
            'description': 'Traditional hand-woven bamboo basket',
            'location': 'Satok Market',
            'price': '149.00'
          },
          {
            'id': 'craft4',
            'name': 'Sarawak Black Pepper Products',
            'description': 'Premium grade Sarawak black pepper',
            'location': 'Carpenter Street',
            'price': '25.00'
          },
          {
            'id': 'craft5',
            'name': 'Melanau Terendak Hat',
            'description': 'Traditional conical hat made from sago leaves',
            'location': 'India Street',
            'price': '79.00'
          },
          {
            'id': 'craft6',
            'name': 'Iban Silver Jewelry Set',
            'description': 'Handcrafted silver jewelry with tribal motifs',
            'location': 'Main Bazaar',
            'price': '399.00'
          }
        ];
      default:
        return [];
    }
  }
} 