import '../../modules/itinerary_personalization/itinerary_model.dart';
import '../models/preference_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:logging/logging.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';

/// A service for providing data while the app is in development or demo mode.
/// This will be gradually replaced by real API calls as the backend is implemented.
class MockDataService {
  final Logger _logger = Logger('MockDataService');
  
  // Cache for city data to avoid recreating it repeatedly
  final Map<String, Map<String, List<Activity>>> _cityActivitiesCache = {};

  // List of available cities in Sarawak
  List<String> getSarawakCities() {
    return [
      'Kuching',
      'Miri',
      'Sibu',
      'Bintulu',
      'Limbang',
      'Sarikei',
      'Kapit',
      'Sri Aman',
      'Serian',
    ];
  }

  // Generate itinerary based on preferences using API
  Future<ItineraryModel> generateItinerary(
    String city,
    PreferenceModel preferences,
    [UserModel? user]
  ) async {
    try {
      _logger.info('Starting itinerary generation for $city');
      
      // Prepare query parameters
      final queryParams = {
        'location': city,
        'food_experiences': preferences.foodPreference.toString(),
        'attractions': preferences.attractionsPreference.toString(),
        'cultural_experiences': preferences.experiencesPreference.toString(),
        'days': preferences.days.toString(),
        'user_name': user?.name ?? 'Guest',
        'user_email': user?.email ?? 'guest@example.com',
        'user_role': user?.role ?? 'tourist',
      };

      final uri = Uri.parse('${AppConfig.apiUrl}/generate_itinerary_json')
          .replace(queryParameters: queryParams);
      
      _logger.fine('API request URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Request timed out after 30 seconds'),
      );

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          return ItineraryModel.fromJson(responseData);
        } catch (e) {
          _logger.warning('Error parsing API response: $e');
          throw Exception('Failed to parse server response: $e');
        }
      } else {
        _logger.warning('API returned status code: ${response.statusCode}');
        throw HttpException('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error generating itinerary: $e');
      
      // Fall back to mock data if API is unavailable
      _logger.info('Falling back to mock data generation');
      return _generateMockItinerary(city, preferences, user);
    }
  }

  // Generate a mock itinerary if API call fails
  ItineraryModel _generateMockItinerary(
    String city,
    PreferenceModel preferences,
    UserModel? user,
  ) {
    final days = <DayPlan>[];
    
    for (int i = 1; i <= preferences.days; i++) {
      days.add(_generateMockDayPlan(i, city));
    }
    
    return ItineraryModel(
      location: city,
      days: days,
      preferences: {
        'days': preferences.days,
        'food_experiences': preferences.foodPreference,
        'attractions': preferences.attractionsPreference,
        'cultural_experiences': preferences.experiencesPreference,
        'user_name': user?.name ?? 'Guest',
      },
      generatedAt: DateTime.now(),
    );
  }

  // Generate a day plan
  Future<DayPlan> generateDayPlan(int dayNumber, String city) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _generateMockDayPlan(dayNumber, city);
  }

  // Generate mock day plan
  DayPlan _generateMockDayPlan(int dayNumber, String city) {
    final Map<String, List<Activity>> schedule = {
      'MORNING': [
        _getActivity(city, 'food', dayNumber * 3 % 10),
        _getActivity(city, 'attraction', dayNumber * 5 % 10),
      ],
      'NOON': [
        _getActivity(city, 'food', (dayNumber * 7 + 1) % 10),
      ],
      'AFTERNOON': [
        _getActivity(city, 'attraction', (dayNumber * 11 + 2) % 10),
        _getActivity(city, 'experience', dayNumber * 13 % 10),
      ],
      'EVENING': [
        _getActivity(city, 'food', (dayNumber * 17 + 3) % 10),
        _getActivity(city, 'experience', (dayNumber * 19 + 4) % 10),
      ],
    };

    return DayPlan(
      dayNumber: dayNumber,
      schedule: schedule,
    );
  }
  
  // Get a mock activity of a specific type
  Activity _getActivity(String city, String type, int index) {
    switch (type) {
      case 'food':
        return _getActivityFromCache(city, type, index, _initializeFoodActivities);
      case 'attraction':
        return _getActivityFromCache(city, type, index, _initializeAttractionActivities);
      case 'experience':
        return _getActivityFromCache(city, type, index, _initializeExperienceActivities);
      default:
        throw ArgumentError('Unknown activity type: $type');
    }
  }
  
  // Get activity from cache or initialize if not present
  Activity _getActivityFromCache(
    String city, 
    String type, 
    int index,
    Map<String, List<Activity>> Function() initializer
  ) {
    // Initialize city in cache if not present
    if (!_cityActivitiesCache.containsKey(city)) {
      _cityActivitiesCache[city] = {};
    }
    
    // Initialize activity type for city if not present
    if (!_cityActivitiesCache[city]!.containsKey(type)) {
      final activities = initializer();
      _cityActivitiesCache[city]![type] = activities[city] ?? activities['Kuching']!;
    }
    
    final activityList = _cityActivitiesCache[city]![type]!;
    final adjustedIndex = index % activityList.length;
    
    return Activity(
      type: activityList[adjustedIndex].type,
      name: activityList[adjustedIndex].name,
      address: activityList[adjustedIndex].address,
      timeSlot: activityList[adjustedIndex].timeSlot,
    );
  }

  // Initialize food activities
  Map<String, List<Activity>> _initializeFoodActivities() {
    return {
      'Kuching': [
        Activity(type: 'food', name: 'Sarawak Laksa', address: 'Choon Hui Cafe, Jalan Ban Hock', timeSlot: '08:00 - 09:30'),
        Activity(type: 'food', name: 'Kolo Mee', address: 'Noodle Descendants, Jalan Padungan', timeSlot: '12:00 - 13:30'),
        Activity(type: 'food', name: 'Manok Pansoh', address: 'Lepau Restaurant, Jalan Ban Hock', timeSlot: '19:00 - 20:30'),
        Activity(type: 'food', name: 'Kueh Lapis Sarawak', address: 'Dayang Salhah, Jalan Datuk Ajibah Abol', timeSlot: '15:00 - 16:00'),
        Activity(type: 'food', name: 'Midin Jungle Fern', address: 'Top Spot Food Court, Jalan Padungan', timeSlot: '18:00 - 19:30'),
      ],
      'Miri': [
        Activity(type: 'food', name: 'Mee Kolok', address: 'Miri Central Market', timeSlot: '08:00 - 09:30'),
        Activity(type: 'food', name: 'Nasi Goreng Kampung', address: 'Ming Cafe, Jalan Yu Seng Selatan', timeSlot: '12:00 - 13:30'),
        Activity(type: 'food', name: 'Umai', address: 'Seahorse Restaurant, Marina Bay', timeSlot: '19:00 - 20:30'),
        Activity(type: 'food', name: 'Ayam Pansuh', address: 'Kelab Miri, Jalan Miri-Bintulu', timeSlot: '15:00 - 16:00'),
      ],
      'Sibu': [
        Activity(type: 'food', name: 'Kompia', address: 'Sibu Central Market', timeSlot: '08:00 - 09:30'),
        Activity(type: 'food', name: 'Kampua Mee', address: 'Paramount Hotel, Jalan Kampung Nyabor', timeSlot: '12:00 - 13:30'),
      ],
    };
  }

  // Initialize attraction activities
  Map<String, List<Activity>> _initializeAttractionActivities() {
    return {
      'Kuching': [
        Activity(type: 'attraction', name: 'Sarawak Cultural Village', address: 'Pantai Damai, Santubong', timeSlot: '09:00 - 12:00'),
        Activity(type: 'attraction', name: 'Semenggoh Wildlife Centre', address: 'Jalan Puncak Borneo', timeSlot: '14:00 - 16:00'),
        Activity(type: 'attraction', name: 'Kuching Waterfront', address: 'Jalan Main Bazaar', timeSlot: '17:00 - 19:00'),
        Activity(type: 'attraction', name: 'Bako National Park', address: 'Bako, Kuching', timeSlot: '15:00 - 18:00'),
      ],
      'Miri': [
        Activity(type: 'attraction', name: 'Niah Caves', address: 'Niah National Park', timeSlot: '09:00 - 12:00'),
        Activity(type: 'attraction', name: 'Canada Hill', address: 'Jalan Peninsula', timeSlot: '14:00 - 16:00'),
        Activity(type: 'attraction', name: 'Miri City Fan', address: 'Jalan Kipas', timeSlot: '17:00 - 19:00'),
      ],
      'Sibu': [
        Activity(type: 'attraction', name: 'Sibu Heritage Centre', address: 'Jalan Central', timeSlot: '10:00 - 12:00'),
      ],
    };
  }

  // Initialize experience activities
  Map<String, List<Activity>> _initializeExperienceActivities() {
    return {
      'Kuching': [
        Activity(type: 'experience', name: 'Traditional Craft Workshop', address: 'Main Bazaar', timeSlot: '10:00 - 12:00'),
        Activity(type: 'experience', name: 'Cooking Class', address: 'Jalan Carpenter', timeSlot: '15:00 - 17:00'),
        Activity(type: 'experience', name: 'Night Market Tour', address: 'Satok Weekend Market', timeSlot: '18:00 - 20:00'),
        Activity(type: 'experience', name: 'Boat tour for Irrawaddy dolphins', address: 'Kuching Wetlands National Park', timeSlot: '16:00 - 18:00'),
      ],
      'Miri': [
        Activity(type: 'experience', name: 'Oil Town Heritage Walk', address: 'Grand Old Lady', timeSlot: '10:00 - 12:00'),
        Activity(type: 'experience', name: 'Night Market Tour', address: 'Miri Handicraft Centre', timeSlot: '18:00 - 20:00'),
      ],
    };
  }
}