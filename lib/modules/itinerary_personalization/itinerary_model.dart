import 'dart:math';

class ItineraryModel {
  final String location;
  final DateTime generatedAt;
  final List<DayPlan> days;
  final Map<String, dynamic> preferences;
  static final Set<String> _usedActivities = {};

  ItineraryModel({
    required this.location,
    required this.generatedAt,
    required this.days,
    required this.preferences,
  });

  // Helper method to check if an activity is unique
  static bool _isUniqueActivity(String name) {
    if (_usedActivities.contains(name)) {
      return false;
    }
    _usedActivities.add(name);
    return true;
  }

  factory ItineraryModel.fromJson(Map<String, dynamic> json) {
    try {
      print('DEBUG: Starting ItineraryModel.fromJson with data: $json');
      
      // Clear used activities for new itinerary
      _usedActivities.clear();

      // Extract preferences directly from the response data
      final Map<String, dynamic> preferences = {
        'food_experiences': json['food_experiences'] ?? 5,
        'attractions': json['attractions'] ?? 3,
        'cultural_experiences': json['cultural_experiences'] ?? 2,
        'days': json['days'] ?? 3,
      };

      print('\nDEBUG: Raw Input Parameters:');
      print('food_experiences: ${json['food_experiences']}');
      print('attractions: ${json['attractions']}');
      print('cultural_experiences: ${json['cultural_experiences']}');
      print('days: ${json['days']}');

      print('\nDEBUG: Using Preferences:');
      print('Days: ${preferences['days']}');
      print('Food Experiences: ${preferences['food_experiences']}');
      print('Attractions: ${preferences['attractions']}');
      print('Cultural Experiences: ${preferences['cultural_experiences']}');

      // Extract activities from the itinerary response
      final List<dynamic> itineraryList = json['itinerary'] as List? ?? [];
      final List<DayPlan> days = [];
      
      // Get the requested number of days directly from preferences
      final int requestedDays = preferences['days'] as int;
      print('\nDEBUG: Creating itinerary for $requestedDays days');

      // Create maps to store unique activities by type
      final Map<String, List<Activity>> allActivities = {
        'food': [],
        'attraction': [],
        'experience': [],
      };

      // First pass: Collect all unique activities from the API response
      for (var dayData in itineraryList) {
        if (dayData is Map<String, dynamic>) {
          final schedule = dayData['schedule'] as Map<String, dynamic>? ?? {};

          for (var timeSlot in ['MORNING', 'NOON', 'AFTERNOON', 'EVENING']) {
            final slotData = schedule[timeSlot] as Map<String, dynamic>? ?? {};

            // Process food activities
            if (slotData['food'] != null) {
              for (var activity in slotData['food'] as List) {
                try {
                  final foodActivity = Activity.fromJson({
                    'type': 'food',
                    'activity': activity,
                    'time_slot': timeSlot,
                  });
                  if (!allActivities['food']!.any((a) => a.name == foodActivity.name)) {
                    allActivities['food']!.add(foodActivity);
                  }
                } catch (e) {
                  print('DEBUG: Error processing food activity: $e');
                  continue;
                }
              }
            }

            // Process attractions
            if (slotData['attraction'] != null) {
              for (var activity in slotData['attraction'] as List) {
                try {
                  final attractionActivity = Activity.fromJson({
                    'type': 'attraction',
                    'activity': activity,
                    'time_slot': timeSlot,
                  });
                  if (!allActivities['attraction']!.any((a) => a.name == attractionActivity.name)) {
                    allActivities['attraction']!.add(attractionActivity);
                  }
                } catch (e) {
                  print('DEBUG: Error processing attraction activity: $e');
                  continue;
                }
              }
            }

            // Process experiences
            if (slotData['experience'] != null) {
              for (var activity in slotData['experience'] as List) {
                try {
                  final experienceActivity = Activity.fromJson({
                    'type': 'experience',
                    'activity': activity,
                    'time_slot': timeSlot,
                  });
                  if (!allActivities['experience']!.any((a) => a.name == experienceActivity.name)) {
                    allActivities['experience']!.add(experienceActivity);
                  }
                } catch (e) {
                  print('DEBUG: Error processing experience activity: $e');
                  continue;
                }
              }
            }
          }
        }
      }

      // Calculate activities per day based on preferences
      final int foodPerDay = preferences['food_experiences'];
      final int attractionsPerDay = preferences['attractions'];
      final int experiencesPerDay = preferences['cultural_experiences'];

      print('\nDEBUG: Activities per day:');
      print('Food per day: $foodPerDay');
      print('Attractions per day: $attractionsPerDay');
      print('Experiences per day: $experiencesPerDay');

      // Calculate total activities needed
      final int totalFoodNeeded = foodPerDay * requestedDays;
      final int totalAttractionsNeeded = attractionsPerDay * requestedDays;
      final int totalExperiencesNeeded = experiencesPerDay * requestedDays;

      print('\nDEBUG: Available activities before distribution:');
      print('Food available: ${allActivities['food']!.length}');
      print('Attractions available: ${allActivities['attraction']!.length}');
      print('Experiences available: ${allActivities['experience']!.length}');

      // Create exactly the number of days requested
      for (var dayNumber = 1; dayNumber <= requestedDays; dayNumber++) {
        print('\nDEBUG: Creating Day $dayNumber of $requestedDays');
        
        final Map<String, List<Activity>> daySchedule = {
          'MORNING': [],
          'NOON': [],
          'AFTERNOON': [],
          'EVENING': [],
        };

        // Get activities for this day
        List<Activity> dayFoodActivities = [];
        List<Activity> dayAttractions = [];
        List<Activity> dayExperiences = [];

        // Get food activities (exactly foodPerDay)
        for (var i = 0; i < foodPerDay; i++) {
          Activity foodActivity;
          if (allActivities['food']!.isEmpty) {
            // If we run out of activities, create a new one based on time of day
            String timeSlot;
            String mealType;
            String description;
            
            if (i == 0) {
              timeSlot = 'MORNING';
              mealType = 'Breakfast';
              description = 'Start your day with authentic Sarawak breakfast. Try Laksa Sarawak, Kolo Mee, or traditional Kampua Mee with local coffee.';
            } else if (i == 1) {
              timeSlot = 'NOON';
              mealType = 'Lunch';
              description = 'Experience local lunch specialties including Nasi Goreng Kampung, Mee Jawa, or fresh seafood from the South China Sea.';
            } else if (i == 2) {
              timeSlot = 'AFTERNOON';
              mealType = 'Tea Time';
              description = 'Enjoy traditional Sarawak tea time with Kek Lapis (layer cake), Kompia, and local kuih-muih.';
            } else if (i == 3) {
              timeSlot = 'EVENING';
              mealType = 'Dinner';
              description = 'Savor authentic Sarawakian dinner with Manok Pansuh (bamboo chicken), Midin (jungle fern), and Umai (raw fish salad).';
            } else {
              timeSlot = 'AFTERNOON';
              mealType = 'Local Snack';
              description = 'Try popular Sarawak snacks like Tebaloi (sago crackers), Sarawak Pineapple Tarts, and traditional rice cakes.';
            }

            // Add specific restaurant locations based on meal type
            String location;
            String address;
            if (mealType == 'Breakfast') {
              location = 'Chong Choon Cafe';
              address = 'Ground Floor, 275, Jalan Chan Chin Ann, 93100 Kuching';
            } else if (mealType == 'Lunch') {
              location = 'Top Spot Food Court';
              address = '6th Floor, Bukit Mata Street, 93100 Kuching';
            } else if (mealType == 'Tea Time') {
              location = 'Kek Lapis Dayang Salhah';
              address = 'Ground Floor, 34, Jalan Tunku Abdul Rahman, 93100 Kuching';
            } else if (mealType == 'Dinner') {
              location = 'Lepau Restaurant';
              address = '79 Jalan Ban Hock, 93100 Kuching';
            } else {
              location = 'Min Joo Cafe';
              address = '35 Carpenter Street, 93000 Kuching';
            }
            
            foodActivity = Activity(
              type: 'food',
              name: '$mealType at $location',
              address: address,
              timeSlot: timeSlot,
              description: description,
            );
          } else {
            foodActivity = allActivities['food']!.removeAt(0);
          }
          dayFoodActivities.add(foodActivity);
        }

        // Get attractions (exactly attractionsPerDay)
        for (var i = 0; i < attractionsPerDay; i++) {
          Activity attractionActivity;
          if (allActivities['attraction']!.isEmpty) {
            String attractionName;
            String attractionAddress;
            String attractionDescription;

            if (i == 0) {
              attractionName = 'Sarawak Cultural Village';
              attractionAddress = 'Pantai Damai, Jalan Santubong, 93050 Kuching';
              attractionDescription = 'Experience the living museum showcasing Sarawak\'s rich cultural heritage with traditional houses, cultural performances, and craft demonstrations.';
            } else if (i == 1) {
              attractionName = 'Bako National Park';
              attractionAddress = 'Bako, 93050 Kuching';
              attractionDescription = 'Explore Sarawak\'s oldest national park featuring diverse wildlife, pristine beaches, and unique rock formations. Home to proboscis monkeys and various tropical species.';
            } else {
              attractionName = 'Semenggoh Wildlife Centre';
              attractionAddress = 'Jalan Tun Abang Haji Openg, 93000 Kuching';
              attractionDescription = 'Visit the renowned orangutan rehabilitation center to observe semi-wild orangutans in their natural habitat during feeding times.';
            }

            attractionActivity = Activity(
              type: 'attraction',
              name: attractionName,
              address: attractionAddress,
              timeSlot: i == 0 ? 'MORNING' : 'AFTERNOON',
              description: attractionDescription,
            );
          } else {
            attractionActivity = allActivities['attraction']!.removeAt(0);
          }
          dayAttractions.add(attractionActivity);
        }

        // Get experiences (exactly experiencesPerDay)
        for (var i = 0; i < experiencesPerDay; i++) {
          Activity experienceActivity;
          if (allActivities['experience']!.isEmpty) {
            String experienceName;
            String experienceAddress;
            String experienceDescription;

            if (i == 0) {
              experienceName = 'Traditional Sarawak Craft Workshop';
              experienceAddress = 'Main Bazaar, 93000 Kuching';
              experienceDescription = 'Learn traditional Sarawak crafts like beadwork, weaving, or pottery making from local artisans. Take home your own handmade souvenir.';
            } else {
              experienceName = 'Evening Cultural Performance';
              experienceAddress = 'Waterfront, Jalan Main Bazaar, 93000 Kuching';
              experienceDescription = 'Experience traditional Sarawak dance and music performances including Ngajat, Datun Julud, and live sape music by local performers.';
            }

            experienceActivity = Activity(
              type: 'experience',
              name: experienceName,
              address: experienceAddress,
              timeSlot: i == 0 ? 'AFTERNOON' : 'EVENING',
              description: experienceDescription,
            );
          } else {
            experienceActivity = allActivities['experience']!.removeAt(0);
          }
          dayExperiences.add(experienceActivity);
        }

        print('DEBUG: Activities collected for Day $dayNumber:');
        print('Food: ${dayFoodActivities.length}/$foodPerDay');
        print('Attractions: ${dayAttractions.length}/$attractionsPerDay');
        print('Experiences: ${dayExperiences.length}/$experiencesPerDay');

        // Distribute activities across time slots
        // Initialize all slots with empty lists
        for (var slot in ['MORNING', 'NOON', 'AFTERNOON', 'EVENING']) {
          daySchedule[slot] = [];
        }

        // Distribute food activities first
        int foodIndex = 0;
        if (foodPerDay > 0 && foodIndex < dayFoodActivities.length) {
          daySchedule['MORNING']!.add(dayFoodActivities[foodIndex++]); // Breakfast
        }
        if (foodPerDay > 1 && foodIndex < dayFoodActivities.length) {
          daySchedule['NOON']!.add(dayFoodActivities[foodIndex++]); // Lunch
        }
        if (foodPerDay > 2 && foodIndex < dayFoodActivities.length) {
          daySchedule['AFTERNOON']!.add(dayFoodActivities[foodIndex++]); // Tea Time
        }
        if (foodPerDay > 3 && foodIndex < dayFoodActivities.length) {
          daySchedule['EVENING']!.add(dayFoodActivities[foodIndex++]); // Dinner
        }
        // Distribute any remaining food activities
        while (foodIndex < dayFoodActivities.length) {
          if (daySchedule['AFTERNOON']!.length < 2) {
            daySchedule['AFTERNOON']!.add(dayFoodActivities[foodIndex++]);
          } else if (daySchedule['EVENING']!.length < 2) {
            daySchedule['EVENING']!.add(dayFoodActivities[foodIndex++]);
          } else {
            break;
          }
        }

        // Distribute attractions
        int attractionIndex = 0;
        if (attractionsPerDay > 0 && attractionIndex < dayAttractions.length) {
          daySchedule['MORNING']!.add(dayAttractions[attractionIndex++]);
        }
        if (attractionsPerDay > 1 && attractionIndex < dayAttractions.length) {
          daySchedule['NOON']!.add(dayAttractions[attractionIndex++]);
        }
        if (attractionsPerDay > 2 && attractionIndex < dayAttractions.length) {
          daySchedule['AFTERNOON']!.add(dayAttractions[attractionIndex++]);
        }

        // Distribute experiences
        int experienceIndex = 0;
        if (experiencesPerDay > 0 && experienceIndex < dayExperiences.length) {
          daySchedule['AFTERNOON']!.add(dayExperiences[experienceIndex++]);
        }
        if (experiencesPerDay > 1 && experienceIndex < dayExperiences.length) {
          daySchedule['EVENING']!.add(dayExperiences[experienceIndex++]);
        }

        days.add(DayPlan(
          dayNumber: dayNumber,
          schedule: daySchedule,
        ));

        print('DEBUG: Added Day $dayNumber to itinerary with activities in slots:');
        print('MORNING: ${daySchedule['MORNING']!.length}');
        print('NOON: ${daySchedule['NOON']!.length}');
        print('AFTERNOON: ${daySchedule['AFTERNOON']!.length}');
        print('EVENING: ${daySchedule['EVENING']!.length}');
        
        // Print detailed food distribution
        print('DEBUG: Food distribution for Day $dayNumber:');
        for (var slot in ['MORNING', 'NOON', 'AFTERNOON', 'EVENING']) {
          var foodCount = daySchedule[slot]!.where((activity) => activity.type == 'food').length;
          print('$slot: $foodCount food activities');
        }
      }

      return ItineraryModel(
        location: json['location']?.toString().toUpperCase() ?? 'KUCHING',
        generatedAt: DateTime.now(),
        days: days,
        preferences: preferences,
      );
    } catch (e, stackTrace) {
      print('DEBUG: Error in ItineraryModel.fromJson: $e');
      print('DEBUG: Stack trace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'location': location,
      'generated_at': generatedAt.toIso8601String(),
      'days': days.map((day) => day.toJson()).toList(),
      'preferences': preferences,
    };
  }
}

class DayPlan {
  final int dayNumber;
  final Map<String, List<Activity>> schedule;

  DayPlan({
    required this.dayNumber,
    required this.schedule,
  });

  Map<String, dynamic> toJson() {
    return {
      'day_number': dayNumber,
      'schedule': schedule.map((timeSlot, activities) {
        // Group activities by type for each time slot
        final Map<String, List<Map<String, dynamic>>> groupedActivities = {
          'food': [],
          'attraction': [],
          'experience': [],
        };

        for (var activity in activities) {
          groupedActivities[activity.type]!.add(activity.toJson());
        }

        return MapEntry(timeSlot, groupedActivities);
      }),
    };
  }
}

class Activity {
  final String type;
  final String name;
  final String address;
  final String timeSlot;
  final String? description;

  Activity({
    required this.type,
    required this.name,
    required this.address,
    required this.timeSlot,
    this.description,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    String type = json['type']?.toString().toLowerCase() ?? '';
    String name = json['name']?.toString() ?? '';
    String address = json['address']?.toString() ?? '';
    String timeSlot = json['time_slot']?.toString() ?? '';
    String? description = json['description']?.toString();

    // Clean up the data
    if (name.isEmpty && json['activity'] != null) {
      String activityStr = json['activity'].toString();
      
      // Extract type if not provided
      if (type.isEmpty) {
        if (activityStr.startsWith('FOOD:')) {
          type = 'food';
          activityStr = activityStr.substring(5);
        } else if (activityStr.startsWith('ATTRACTION:')) {
          type = 'attraction';
          activityStr = activityStr.substring(11);
        } else if (activityStr.startsWith('EXPERIENCE:')) {
          type = 'experience';
          activityStr = activityStr.substring(11);
        }
      }

      // Extract name and address
      final parts = activityStr.split(', Address:');
      if (parts.length > 1) {
        name = parts[0].replaceFirst(RegExp(r'^(Food:|Attraction:|Experience:)\s*'), '').trim();
        address = parts[1].trim();
      } else {
        name = activityStr.replaceFirst(RegExp(r'^(Food:|Attraction:|Experience:)\s*'), '').trim();
        // Set a default address if none provided
        address = 'Kuching City Center';
      }
    }

    // Enhance address formatting
    if (!address.toLowerCase().contains('kuching')) {
      address = '$address, Kuching';
    }
    
    if (!address.toLowerCase().contains('sarawak')) {
      address = '$address, Sarawak';
    }

    // Add postal code if missing
    if (!RegExp(r'\d{5}').hasMatch(address)) {
      // Use specific postal codes for known areas
      if (address.toLowerCase().contains('waterfront')) {
        address = '$address, 93000';
      } else if (address.toLowerCase().contains('padungan')) {
        address = '$address, 93100';
      } else if (address.toLowerCase().contains('pending')) {
        address = '$address, 93450';
      } else if (address.toLowerCase().contains('santubong') || 
                 address.toLowerCase().contains('damai')) {
        address = '$address, 93050';
      } else if (address.toLowerCase().contains('batu kawa')) {
        address = '$address, 93250';
      } else if (address.toLowerCase().contains('batu lintang')) {
        address = '$address, 93200';
      } else if (address.toLowerCase().contains('petra jaya')) {
        address = '$address, 93050';
      } else {
        // Default postal code for central Kuching
        address = '$address, 93000';
      }
    }

    // Add landmark/building details if available
    if (name.toLowerCase().contains('at ')) {
      final locationParts = name.split(' at ');
      name = locationParts[0].trim();
      if (locationParts.length > 1) {
        address = '${locationParts[1].trim()}, $address';
      }
    }

    // Clean up any double spaces or commas
    address = address.replaceAll(RegExp(r'\s+'), ' ')
                    .replaceAll(RegExp(r',\s*,'), ',')
                    .replaceAll(RegExp(r',\s*$'), '')
                    .trim();

    // Add specific location details based on type
    if (type == 'food' && !address.toLowerCase().contains('food court') && 
        !address.toLowerCase().contains('restaurant') && 
        !address.toLowerCase().contains('cafe')) {
      if (name.toLowerCase().contains('food court')) {
        address = 'Food Court, $address';
      } else {
        address = 'Restaurant/Cafe, $address';
      }
    }

    return Activity(
      type: type,
      name: name,
      address: address,
      timeSlot: timeSlot,
      description: description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      'address': address,
      'time_slot': timeSlot,
      if (description != null) 'description': description,
    };
  }
} 