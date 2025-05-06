import 'package:flutter/material.dart';
import '../../../shared/services/recommendation_service.dart';
import 'recommendation_list_view_base.dart'; // Import base class

// View for Activities (formerly Experiences)
class ActivityView extends RecommendationListViewBase {
   const ActivityView({
    Key? key,
    required RecommendationService recommendationService,
    required String selectedCity,
    required Animation<double> fadeAnimation,
    required RecommendationCardBuilder cardBuilder, // Accept the builder function
  }) : super(
          key: key,
          recommendationService: recommendationService,
          selectedCity: selectedCity,
          categoryKey: 'experience', // Changed from 'experiences' to match submission system
          fadeAnimation: fadeAnimation,
          cardBuilder: cardBuilder, // Pass it to the base class
        );
}
