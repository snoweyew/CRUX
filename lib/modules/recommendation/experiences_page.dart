import 'package:flutter/material.dart';
import '../../shared/models/user_model.dart';
import '../../shared/services/navigation_service.dart';
import '../../shared/services/mock_data_service.dart';
import '../../shared/services/recommendation_service.dart';
import '../../shared/config/app_config.dart';
import '../itinerary_personalization/itinerary_model.dart';
import 'base_recommendation_page.dart';

class ExperiencesPage extends BaseRecommendationPage {
  const ExperiencesPage({
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
  State<ExperiencesPage> createState() => _ExperiencesPageState();
}

class _ExperiencesPageState extends BaseRecommendationPageState<ExperiencesPage> {
  @override
  String getPageTitle() {
    return 'Experiences';
  }

  @override
  IconData getPageIcon() {
    return Icons.theater_comedy;
  }

  @override
  int getCategoryIndex() {
    return 2; // Experiences is the third category
  }

  @override
  String getCategoryImage() {
    return 'assets/images/experiences_placeholder.jpg';
  }

  @override
  Future<List<Map<String, String>>> getRecommendations() async {
    if (AppConfig.enableMockData) {
      return widget.recommendationService.getMockRecommendations('experiences');
    }
    try {
      return await widget.recommendationService.getExperiences();
    } catch (e) {
      // Fallback to mock data if API fails
      return widget.recommendationService.getMockRecommendations('experiences');
    }
  }
} 