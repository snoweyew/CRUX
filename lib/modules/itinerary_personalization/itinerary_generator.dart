import '../../shared/models/preference_model.dart';
import '../../shared/services/mock_data_service.dart';
import '../../shared/services/itinerary_storage_service.dart';
import 'itinerary_model.dart';

class ItineraryGenerator {
  final MockDataService _mockDataService;
  final ItineraryStorageService _storageService = ItineraryStorageService();

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

  // Save the current itinerary to local storage
  Future<bool> saveItinerary(ItineraryModel itinerary) async {
    return await _storageService.saveItinerary(itinerary);
  }
  
  // Check if there are any saved itineraries
  Future<bool> hasSavedItineraries() async {
    return await _storageService.hasSavedItineraries();
  }
  
  // Get all saved itineraries
  Future<List<ItineraryModel>> getSavedItineraries() async {
    return await _storageService.getSavedItineraries();
  }

  // Regenerate a specific day in an itinerary
  Future<ItineraryModel> regenerateDay(
    ItineraryModel itinerary,
    int dayNumber,
    PreferenceModel preferences,
  ) async {
    // Generate a new day plan
    final newDayPlan = await _generateSingleDay(
      itinerary.location,
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
      location: itinerary.location,
      generatedAt: DateTime.now(),
      days: updatedDays,
      preferences: itinerary.preferences,
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
      schedule: dayPlan.schedule,
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
        type: activity.type,
        name: 'Alternative ${index + 1} to ${activity.name}',
        address: 'Alternative Address ${index + 1}, $city',
        timeSlot: activity.timeSlot,
        description: 'An alternative option to ${activity.description ?? activity.name}',
      );
    });
  }
}