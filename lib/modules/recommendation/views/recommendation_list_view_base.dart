import 'package:flutter/material.dart';
import '../../../shared/services/recommendation_service.dart';
import '../../../shared/config/app_config.dart'; // Assuming AppConfig might be used

// Type definition for the card builder function
typedef RecommendationCardBuilder = Widget Function(BuildContext context, Map<String, String> recommendation);

// Base class for recommendation list views
class RecommendationListViewBase extends StatelessWidget {
  final RecommendationService recommendationService;
  final String selectedCity;
  final String categoryKey; // Key for fetching data (e.g., 'attractions', 'food')
  final Animation<double> fadeAnimation;
  final RecommendationCardBuilder cardBuilder; // Function to build each card

  const RecommendationListViewBase({
    Key? key,
    required this.recommendationService,
    required this.selectedCity,
    required this.categoryKey,
    required this.fadeAnimation,
    required this.cardBuilder, // Require the card builder
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, String>>>(
      // Fetch data using the service based on categoryKey and city
      // Using mock data for now, adjust as needed for real API
      future: Future.value(recommendationService.getMockRecommendations(categoryKey, city: selectedCity)),
      // future: AppConfig.enableMockData
      //     ? Future.value(recommendationService.getMockRecommendations(categoryKey, city: selectedCity))
      //     : recommendationService.fetchRecommendations(categoryKey, city: selectedCity), // Hypothetical API
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading recommendations: \${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text('No recommendations found for \$selectedCity in the \$categoryKey category.'),
          );
        }

        final recommendations = snapshot.data!;

        return FadeTransition(
          opacity: fadeAnimation,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              final recommendation = recommendations[index];
              // Use the passed cardBuilder function
              return cardBuilder(context, recommendation);
            },
          ),
        );
      },
    );
  }
}
