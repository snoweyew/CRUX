import 'package:flutter/material.dart';
import '../../shared/models/user_model.dart';
import '../../shared/services/navigation_service.dart';
import '../../shared/services/mock_data_service.dart';
import '../../shared/services/recommendation_service.dart';
import '../../shared/config/app_config.dart';
import '../itinerary_personalization/itinerary_model.dart';
import 'base_recommendation_page.dart';

class EventsPage extends BaseRecommendationPage {
  const EventsPage({
    Key? key,
    required UserModel user,
    required NavigationService navigationService,
    required MockDataService mockDataService,
    required ItineraryModel? itinerary,
    required RecommendationService recommendationService,
  }) : super(
          key: key,
          user: user,
          navigationService: navigationService,
          mockDataService: mockDataService,
          itinerary: itinerary,
          recommendationService: recommendationService,
        );

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends BaseRecommendationPageState<EventsPage> {
  @override
  String getPageTitle() {
    return 'Events';
  }

  @override
  IconData getPageIcon() {
    return Icons.event;
  }

  @override
  int getCategoryIndex() {
    return 0; // Events is the first category
  }

  @override
  String getCategoryImage() {
    return 'assets/images/events_placeholder.jpg';
  }

  @override
  Future<List<Map<String, String>>> getRecommendations() async {
    if (AppConfig.enableMockData) {
      return widget.recommendationService.getMockRecommendations('events');
    }
    try {
      return await widget.recommendationService.getEvents();
    } catch (e) {
      // Fallback to mock data if API fails
      return widget.recommendationService.getMockRecommendations('events');
    }
  }
} 