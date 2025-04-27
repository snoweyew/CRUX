// Export all recommendation pages for easier importing
export 'events_page.dart';
export 'food_page.dart';
export 'experiences_page.dart';
export 'attractions_page.dart';
export 'shopping_page.dart';
export 'cart_item.dart';
export 'base_recommendation_page.dart';

// Re-implement the factory method here to avoid circular imports
import 'package:flutter/material.dart';
import '../../shared/models/user_model.dart';
import '../../shared/services/navigation_service.dart';
import '../../shared/services/mock_data_service.dart';
import '../../shared/services/recommendation_service.dart';
import '../itinerary_personalization/itinerary_model.dart';
import 'base_recommendation_page.dart';
import 'events_page.dart';
import 'food_page.dart';
import 'experiences_page.dart';
import 'attractions_page.dart';
import 'shopping_page.dart';

// Extend the factory method
extension RecommendationPageFactory on BaseRecommendationPage {
  static Widget createPage(
    int index,
    UserModel user,
    NavigationService navigationService,
    MockDataService mockDataService,
    ItineraryModel? itinerary,
    RecommendationService recommendationService,
    BuildContext context,
  ) {
    switch (index) {
      case 0:
        return EventsPage(
          user: user,
          navigationService: navigationService,
          mockDataService: mockDataService,
          itinerary: itinerary,
          recommendationService: recommendationService,
        );
      case 1:
        return FoodPage(
          user: user,
          navigationService: navigationService,
          mockDataService: mockDataService,
          itinerary: itinerary,
          recommendationService: recommendationService,
        );
      case 2:
        return ExperiencesPage(
          user: user,
          navigationService: navigationService,
          mockDataService: mockDataService,
          itinerary: itinerary,
          recommendationService: recommendationService,
        );
      case 3:
        return AttractionsPage(
          user: user,
          navigationService: navigationService,
          mockDataService: mockDataService,
          itinerary: itinerary,
          recommendationService: recommendationService,
        );
      case 4:
        return ShoppingPage(
          user: user,
          navigationService: navigationService,
          mockDataService: mockDataService,
          itinerary: itinerary,
          recommendationService: recommendationService,
        );
      default:
        return EventsPage(
          user: user,
          navigationService: navigationService,
          mockDataService: mockDataService,
          itinerary: itinerary,
          recommendationService: recommendationService,
        );
    }
  }
} 