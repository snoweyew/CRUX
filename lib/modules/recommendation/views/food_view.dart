import 'package:flutter/material.dart';
import '../../../shared/services/recommendation_service.dart';
import 'recommendation_list_view_base.dart'; // Import base class

// View for Food
class FoodView extends RecommendationListViewBase {
   const FoodView({
    Key? key,
    required RecommendationService recommendationService,
    required String selectedCity,
    required Animation<double> fadeAnimation,
    required RecommendationCardBuilder cardBuilder, // Accept the builder function
  }) : super(
          key: key,
          recommendationService: recommendationService,
          selectedCity: selectedCity,
          categoryKey: 'food',
          fadeAnimation: fadeAnimation,
          cardBuilder: cardBuilder, // Pass it to the base class
        );
}
