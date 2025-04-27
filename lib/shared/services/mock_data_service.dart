import '../../modules/itinerary_personalization/itinerary_model.dart';
import '../models/preference_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import '../config/app_config.dart';
import '../models/user_model.dart';

class MockDataService {
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
      print('DEBUG: Starting API call');
      print('DEBUG: User data: ${user?.toJson()}');
      print('DEBUG: Preferences: ${preferences.toJson()}');
      print('DEBUG: API URL base: ${AppConfig.apiUrl}');

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
      
      print('DEBUG: Full request URL: $uri');

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

      print('DEBUG: Response received');
      print('DEBUG: Status code: ${response.statusCode}');
      print('DEBUG: Response headers: ${response.headers}');
      print('DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          print('DEBUG: Successfully decoded JSON: $responseData');
          
          final itinerary = ItineraryModel.fromJson(responseData);
          print('DEBUG: Successfully created ItineraryModel');
          
          return itinerary;
        } catch (e) {
          print('DEBUG: Error parsing response: $e');
          throw Exception('Failed to parse server response: $e');
        }
      } else {
        print('DEBUG: Server returned error status: ${response.statusCode}');
        throw HttpException('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error generating itinerary: $e');
      rethrow;
    }
  }

  // Generate a day plan
  Future<DayPlan> generateDayPlan(int dayNumber) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final Map<String, List<Activity>> schedule = {
      'MORNING': [
        Activity(
          type: 'food',
          name: 'Sarawak Laksa',
          address: '123 Food Street',
          timeSlot: 'MORNING',
        ),
        Activity(
          type: 'attraction',
          name: 'Kuching Waterfront',
          address: '456 Waterfront Road',
          timeSlot: 'MORNING',
        ),
      ],
      'NOON': [
        Activity(
          type: 'food',
          name: 'Kolo Mee',
          address: '789 Noodle Lane',
          timeSlot: 'NOON',
        ),
      ],
      'AFTERNOON': [
        Activity(
          type: 'attraction',
          name: 'Sarawak Museum',
          address: '321 Museum Street',
          timeSlot: 'AFTERNOON',
        ),
        Activity(
          type: 'experience',
          name: 'Traditional Dance Show',
          address: '654 Cultural Center',
          timeSlot: 'AFTERNOON',
        ),
      ],
      'EVENING': [
        Activity(
          type: 'food',
          name: 'Seafood Dinner',
          address: '987 Seafood Street',
          timeSlot: 'EVENING',
        ),
        Activity(
          type: 'experience',
          name: 'Night Market Visit',
          address: '147 Market Road',
          timeSlot: 'EVENING',
        ),
      ],
    };

    return DayPlan(
      dayNumber: dayNumber,
      schedule: schedule,
    );
  }

  // Helper method to check if a time slot is empty
  bool _isSlotEmpty(Map<String, List<Activity>> slot) {
    return slot.values.every((activities) => activities.isEmpty);
  }

  // Helper method to check if a time slot has a specific activity type
  bool _hasActivityType(Map<String, List<Activity>> slot, String type) {
    return slot[type]?.isNotEmpty ?? false;
  }

  String _getTimeSlot(String timeSlot) {
    final hour = int.parse(timeSlot.split(':')[0]);
    if (hour >= 6 && hour < 12) return 'MORNING';
    if (hour >= 12 && hour < 15) return 'NOON';
    if (hour >= 15 && hour < 18) return 'AFTERNOON';
    return 'EVENING';
  }

  // Get a mock food activity
  Activity _getMockFoodActivity(String city, int index, int day) {
    final foodActivities = {
      'Kuching': [
        Activity(
          type: 'food',
          name: 'Sarawak Laksa',
          address: 'Choon Hui Cafe, Jalan Ban Hock',
          timeSlot: '08:00 - 09:30',
        ),
        Activity(
          type: 'food',
          name: 'Kolo Mee',
          address: 'Noodle Descendants, Jalan Padungan',
          timeSlot: '12:00 - 13:30',
        ),
        Activity(
          type: 'food',
          name: 'Manok Pansoh',
          address: 'Lepau Restaurant, Jalan Ban Hock',
          timeSlot: '19:00 - 20:30',
        ),
        Activity(
          type: 'food',
          name: 'Kueh Lapis Sarawak',
          address: 'Dayang Salhah, Jalan Datuk Ajibah Abol',
          timeSlot: '15:00 - 16:00',
        ),
        Activity(
          type: 'food',
          name: 'Midin Jungle Fern',
          address: 'Top Spot Food Court, Jalan Padungan',
          timeSlot: '18:00 - 19:30',
        ),
        Activity(
          type: 'food',
          name: 'Nasi Goreng Dabai',
          address: 'Warung Nasi Goreng Dabai, Petra Jaya',
          timeSlot: '16:00 - 17:30',
        ),
        Activity(
          type: 'food',
          name: 'Nasi Ayam',
          address: 'Jalan Padungan',
          timeSlot: '12:00 - 13:30',
        ),
        Activity(
          type: 'food',
          name: 'Prawn fritters',
          address: 'Santubong Village stalls',
          timeSlot: '15:00 - 16:30',
        ),
      ],
      'Miri': [
        Activity(
          type: 'food',
          name: 'Mee Kolok',
          address: 'Miri Central Market',
          timeSlot: '08:00 - 09:30',
        ),
        Activity(
          type: 'food',
          name: 'Nasi Goreng Kampung',
          address: 'Ming Cafe, Jalan Yu Seng Selatan',
          timeSlot: '12:00 - 13:30',
        ),
        Activity(
          type: 'food',
          name: 'Umai',
          address: 'Seahorse Restaurant, Marina Bay',
          timeSlot: '19:00 - 20:30',
        ),
        Activity(
          type: 'food',
          name: 'Ayam Pansuh',
          address: 'Kelab Miri, Jalan Miri-Bintulu',
          timeSlot: '15:00 - 16:00',
        ),
        Activity(
          type: 'food',
          name: 'Sarawak Layer Cake',
          address: 'Miri Handicraft Centre',
          timeSlot: '16:30 - 17:30',
        ),
      ],
    };

    final cityFoods = foodActivities[city] ?? foodActivities['Kuching']!;
    final adjustedIndex = index % cityFoods.length;
    
    final activity = cityFoods[adjustedIndex];
    return Activity(
      type: activity.type,
      name: activity.name,
      address: activity.address,
      timeSlot: activity.timeSlot,
    );
  }

  // Get a mock attraction activity
  Activity _getMockAttractionActivity(String city, int index, int day) {
    final attractionActivities = {
      'Kuching': [
        Activity(
          type: 'attraction',
          name: 'Sarawak Cultural Village',
          address: 'Pantai Damai, Santubong',
          timeSlot: '09:00 - 12:00',
        ),
        Activity(
          type: 'attraction',
          name: 'Semenggoh Wildlife Centre',
          address: 'Jalan Puncak Borneo',
          timeSlot: '14:00 - 16:00',
        ),
        Activity(
          type: 'attraction',
          name: 'Kuching Waterfront',
          address: 'Jalan Main Bazaar',
          timeSlot: '17:00 - 19:00',
        ),
        Activity(
          type: 'attraction',
          name: 'Bako National Park',
          address: 'Bako, Kuching',
          timeSlot: '15:00 - 18:00',
        ),
        Activity(
          type: 'attraction',
          name: 'Wind Cave Nature Reserve',
          address: 'Bau, 94000 Kuching',
          timeSlot: '14:00 - 16:00',
        ),
        Activity(
          type: 'attraction',
          name: 'Annah Rais Longhouse',
          address: 'Padawan, 94200 Kuching',
          timeSlot: '15:00 - 17:00',
        ),
      ],
      'Miri': [
        Activity(
          type: 'attraction',
          name: 'Niah Caves',
          address: 'Niah National Park',
          timeSlot: '09:00 - 12:00',
        ),
        Activity(
          type: 'attraction',
          name: 'Canada Hill',
          address: 'Jalan Peninsula',
          timeSlot: '14:00 - 16:00',
        ),
        Activity(
          type: 'attraction',
          name: 'Miri City Fan',
          address: 'Jalan Kipas',
          timeSlot: '17:00 - 19:00',
        ),
      ],
    };

    final cityAttractions = attractionActivities[city] ?? attractionActivities['Kuching']!;
    final adjustedIndex = index % cityAttractions.length;
    
    final activity = cityAttractions[adjustedIndex];
    return Activity(
      type: activity.type,
      name: activity.name,
      address: activity.address,
      timeSlot: activity.timeSlot,
    );
  }

  // Get a mock experience activity
  Activity _getMockExperienceActivity(String city, int index, int day) {
    final experienceActivities = {
      'Kuching': [
        Activity(
          type: 'experience',
          name: 'Traditional Craft Workshop',
          address: 'Main Bazaar',
          timeSlot: '10:00 - 12:00',
        ),
        Activity(
          type: 'experience',
          name: 'Cooking Class',
          address: 'Jalan Carpenter',
          timeSlot: '15:00 - 17:00',
        ),
        Activity(
          type: 'experience',
          name: 'Night Market Tour',
          address: 'Satok Weekend Market',
          timeSlot: '18:00 - 20:00',
        ),
        Activity(
          type: 'experience',
          name: 'Boat tour for Irrawaddy dolphins',
          address: 'Kuching Wetlands National Park',
          timeSlot: '16:00 - 18:00',
        ),
      ],
      'Miri': [
        Activity(
          type: 'experience',
          name: 'Oil Town Heritage Walk',
          address: 'Grand Old Lady',
          timeSlot: '10:00 - 12:00',
        ),
        Activity(
          type: 'experience',
          name: 'Night Market Tour',
          address: 'Miri Handicraft Centre',
          timeSlot: '18:00 - 20:00',
        ),
      ],
    };

    final cityExperiences = experienceActivities[city] ?? experienceActivities['Kuching']!;
    final adjustedIndex = index % cityExperiences.length;
    
    final activity = cityExperiences[adjustedIndex];
    return Activity(
      type: activity.type,
      name: activity.name,
      address: activity.address,
      timeSlot: activity.timeSlot,
    );
  }
} 