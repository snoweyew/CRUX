import 'package:flutter/material.dart';
import '../../shared/models/user_model.dart';
import '../../shared/services/navigation_service.dart';
import '../../shared/services/mock_data_service.dart';
import '../../shared/services/recommendation_service.dart';
import '../../shared/config/app_config.dart';
import '../itinerary_personalization/itinerary_model.dart';
import 'base_recommendation_page.dart';

class FoodPage extends BaseRecommendationPage {
  const FoodPage({
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
  State<FoodPage> createState() => _FoodPageState();
}

class _FoodPageState extends BaseRecommendationPageState<FoodPage> {
  @override
  String getPageTitle() {
    return 'Food';
  }

  @override
  IconData getPageIcon() {
    return Icons.restaurant;
  }

  @override
  int getCategoryIndex() {
    return 1; // Food is the second category
  }

  @override
  String getCategoryImage() {
    return 'assets/images/food_placeholder.jpg';
  }

  @override
  Future<List<Map<String, String>>> getRecommendations() async {
    if (AppConfig.enableMockData) {
      return widget.recommendationService.getMockRecommendations('food');
    }
    try {
      return await widget.recommendationService.getFood();
    } catch (e) {
      // Fallback to mock data if API fails
      return widget.recommendationService.getMockRecommendations('food');
    }
  }
} 