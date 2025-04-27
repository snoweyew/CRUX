import '../../shared/models/preference_model.dart';
import 'itinerary_model.dart';

class ItineraryCustomizer {
  // Adjust an existing itinerary based on new preferences
  static ItineraryModel customizeItinerary(
    ItineraryModel itinerary,
    PreferenceModel oldPreferences,
    PreferenceModel newPreferences,
  ) {
    // If days changed, we need to add or remove days
    if (oldPreferences.days != newPreferences.days) {
      itinerary = _adjustDays(itinerary, oldPreferences.days, newPreferences.days);
    }

    // Adjust activities in each day based on new preferences
    final List<DayPlan> adjustedDays = [];
    
    for (final day in itinerary.days) {
      adjustedDays.add(_adjustActivities(
        day,
        oldPreferences,
        newPreferences,
      ));
    }

    return ItineraryModel(
      id: itinerary.id,
      city: itinerary.city,
      days: adjustedDays,
      createdAt: DateTime.now(), // Update creation date
    );
  }

  // Add or remove days from the itinerary
  static ItineraryModel _adjustDays(
    ItineraryModel itinerary,
    int oldDays,
    int newDays,
  ) {
    final List<DayPlan> adjustedDays = List.from(itinerary.days);
    
    if (newDays > oldDays) {
      // Add more days
      for (int i = oldDays + 1; i <= newDays; i++) {
        // Clone activities from an existing day and adjust
        final activitiesToClone = itinerary.days[0].activities;
        final clonedActivities = activitiesToClone.map((activity) {
          return Activity(
            id: '${activity.id}-day$i',
            name: activity.name,
            description: activity.description,
            type: activity.type,
            imageUrl: activity.imageUrl,
            location: activity.location,
            timeSlot: activity.timeSlot,
          );
        }).toList();
        
        adjustedDays.add(DayPlan(
          dayNumber: i,
          activities: clonedActivities,
        ));
      }
    } else if (newDays < oldDays) {
      // Remove days
      adjustedDays.removeRange(newDays, oldDays);
    }
    
    return ItineraryModel(
      id: itinerary.id,
      city: itinerary.city,
      days: adjustedDays,
      createdAt: itinerary.createdAt,
    );
  }

  // Adjust activities in a day based on new preferences
  static DayPlan _adjustActivities(
    DayPlan day,
    PreferenceModel oldPreferences,
    PreferenceModel newPreferences,
  ) {
    // Group activities by type
    final Map<String, List<Activity>> activitiesByType = {
      'food': [],
      'attraction': [],
      'experience': [],
    };
    
    for (final activity in day.activities) {
      activitiesByType[activity.type]?.add(activity);
    }
    
    // Adjust food activities
    final foodActivities = _adjustActivityCount(
      activitiesByType['food'] ?? [],
      oldPreferences.foodPreference,
      newPreferences.foodPreference,
      'food',
      day.dayNumber,
    );
    
    // Adjust attraction activities
    final attractionActivities = _adjustActivityCount(
      activitiesByType['attraction'] ?? [],
      oldPreferences.attractionsPreference,
      newPreferences.attractionsPreference,
      'attraction',
      day.dayNumber,
    );
    
    // Adjust experience activities
    final experienceActivities = _adjustActivityCount(
      activitiesByType['experience'] ?? [],
      oldPreferences.experiencesPreference,
      newPreferences.experiencesPreference,
      'experience',
      day.dayNumber,
    );
    
    // Combine all activities and sort by time slot
    final allActivities = [
      ...foodActivities,
      ...attractionActivities,
      ...experienceActivities,
    ];
    
    allActivities.sort((a, b) => a.timeSlot.compareTo(b.timeSlot));
    
    return DayPlan(
      dayNumber: day.dayNumber,
      activities: allActivities,
    );
  }

  // Adjust the count of activities of a specific type
  static List<Activity> _adjustActivityCount(
    List<Activity> activities,
    int oldCount,
    int newCount,
    String type,
    int dayNumber,
  ) {
    if (newCount == oldCount) {
      return activities;
    }
    
    if (newCount > oldCount) {
      // Add more activities
      final additionalCount = newCount - oldCount;
      final additionalActivities = List.generate(additionalCount, (index) {
        final baseActivity = activities.isNotEmpty
            ? activities[index % activities.length]
            : _createDefaultActivity(type, dayNumber);
            
        return Activity(
          id: '${baseActivity.id}-additional-${index + 1}',
          name: '${baseActivity.name} ${index + 1}',
          description: baseActivity.description,
          type: baseActivity.type,
          imageUrl: baseActivity.imageUrl,
          location: baseActivity.location,
          timeSlot: _adjustTimeSlot(baseActivity.timeSlot, index + 1),
        );
      });
      
      return [...activities, ...additionalActivities];
    } else {
      // Remove activities
      return activities.sublist(0, newCount);
    }
  }

  // Create a default activity if none exists
  static Activity _createDefaultActivity(String type, int dayNumber) {
    switch (type) {
      case 'food':
        return Activity(
          id: 'default-food-day$dayNumber',
          name: 'Local Food Experience',
          description: 'Enjoy local cuisine and flavors.',
          type: 'food',
          imageUrl: 'https://example.com/default-food.jpg',
          location: 'Local Restaurant',
          timeSlot: '12:00 - 13:30',
        );
      case 'attraction':
        return Activity(
          id: 'default-attraction-day$dayNumber',
          name: 'Local Attraction',
          description: 'Visit a popular local attraction.',
          type: 'attraction',
          imageUrl: 'https://example.com/default-attraction.jpg',
          location: 'City Center',
          timeSlot: '10:00 - 12:00',
        );
      case 'experience':
        return Activity(
          id: 'default-experience-day$dayNumber',
          name: 'Cultural Experience',
          description: 'Immerse yourself in local culture.',
          type: 'experience',
          imageUrl: 'https://example.com/default-experience.jpg',
          location: 'Cultural Center',
          timeSlot: '15:00 - 17:00',
        );
      default:
        return Activity(
          id: 'default-activity-day$dayNumber',
          name: 'Default Activity',
          description: 'A placeholder activity.',
          type: type,
          imageUrl: 'https://example.com/default.jpg',
          location: 'Various Locations',
          timeSlot: '09:00 - 10:00',
        );
    }
  }

  // Adjust time slot to avoid conflicts
  static String _adjustTimeSlot(String timeSlot, int offset) {
    final parts = timeSlot.split(' - ');
    final startTime = parts[0].split(':');
    final endTime = parts[1].split(':');
    
    final startHour = (int.parse(startTime[0]) + offset) % 24;
    final endHour = (int.parse(endTime[0]) + offset) % 24;
    
    return '${startHour.toString().padLeft(2, '0')}:${startTime[1]} - ${endHour.toString().padLeft(2, '0')}:${endTime[1]}';
  }
} 