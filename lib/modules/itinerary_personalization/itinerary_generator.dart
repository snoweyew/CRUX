import '../../shared/models/preference_model.dart';
import '../../shared/services/mock_data_service.dart';
import 'itinerary_model.dart';

class ItineraryGenerator {
  final MockDataService _mockDataService;

  ItineraryGenerator(this._mockDataService);

  // Generate an itinerary based on user preferences
  Future<ItineraryModel> generateItinerary(
    String city,
    PreferenceModel preferences,
  ) async {
    // In a real app, this would call an AI service or backend API
    // For now, we'll use the mock data service
    return await _mockDataService.generateItinerary(city, preferences);
  }

  // Regenerate a specific day in an itinerary
  Future<ItineraryModel> regenerateDay(
    ItineraryModel itinerary,
    int dayNumber,
    PreferenceModel preferences,
  ) async {
    // Generate a new day plan
    final newDayPlan = await _generateSingleDay(
      itinerary.city,
      dayNumber,
      preferences,
    );

    // Replace the day in the itinerary
    final updatedDays = itinerary.days.map((day) {
      if (day.dayNumber == dayNumber) {
        return newDayPlan;
      }
      return day;
    }).toList();

    // Return the updated itinerary
    return ItineraryModel(
      id: itinerary.id,
      city: itinerary.city,
      days: updatedDays,
      createdAt: DateTime.now(),
    );
  }

  // Generate a single day plan
  Future<DayPlan> _generateSingleDay(
    String city,
    int dayNumber,
    PreferenceModel preferences,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Create a temporary itinerary with just one day
    final tempPreferences = PreferenceModel(
      foodPreference: preferences.foodPreference,
      attractionsPreference: preferences.attractionsPreference,
      experiencesPreference: preferences.experiencesPreference,
      days: 1,
    );

    final tempItinerary = await _mockDataService.generateItinerary(
      city,
      tempPreferences,
    );

    // Update the day number
    final dayPlan = tempItinerary.days.first;
    return DayPlan(
      dayNumber: dayNumber,
      activities: dayPlan.activities,
    );
  }

  // Suggest alternative activities for a specific activity
  Future<List<Activity>> suggestAlternatives(
    Activity activity,
    String city,
    int count,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    // In a real app, this would call an AI service or backend API
    // For now, we'll generate some mock alternatives
    return List.generate(count, (index) {
      return Activity(
        id: '${activity.id}-alt-${index + 1}',
        name: 'Alternative ${index + 1} to ${activity.name}',
        description: 'An alternative option to ${activity.description}',
        type: activity.type,
        imageUrl: activity.imageUrl,
        location: 'Alternative Location ${index + 1}',
        timeSlot: activity.timeSlot,
      );
    });
  }
} 