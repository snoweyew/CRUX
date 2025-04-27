import 'package:flutter/material.dart';
import '../../shared/models/user_model.dart';
import '../../shared/services/navigation_service.dart';
import '../../shared/services/mock_data_service.dart';
import '../../shared/services/recommendation_service.dart';
import '../../shared/config/app_config.dart';
import '../itinerary_personalization/itinerary_model.dart';
import 'base_recommendation_page.dart';

class AttractionsPage extends BaseRecommendationPage {
  const AttractionsPage({
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
  State<AttractionsPage> createState() => _AttractionsPageState();
}

class _AttractionsPageState extends BaseRecommendationPageState<AttractionsPage> {
  @override
  String getPageTitle() {
    return 'Attractions';
  }

  @override
  IconData getPageIcon() {
    return Icons.photo_camera;
  }

  @override
  int getCategoryIndex() {
    return 3; // Attractions is the fourth category
  }

  @override
  String getCategoryImage() {
    return 'assets/images/attractions_placeholder.jpg';
  }

  @override
  Future<List<Map<String, String>>> getRecommendations() async {
    if (AppConfig.enableMockData) {
      return widget.recommendationService.getMockRecommendations('attractions');
    }
    try {
      return await widget.recommendationService.getAttractions();
    } catch (e) {
      // Fallback to mock data if API fails
      return widget.recommendationService.getMockRecommendations('attractions');
    }
  }
} 