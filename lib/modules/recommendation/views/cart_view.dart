import 'package:flutter/material.dart';
import '../../../shared/services/recommendation_service.dart';
import '../../../shared/config/app_config.dart'; // Assuming AppConfig might be used

// Type definition for the shopping card builder function
typedef ShoppingCardBuilder = Widget Function(BuildContext context, Map<String, String> recommendation, ValueChanged<Map<String, String>> onAddToCart);

// View for Cart (formerly Shopping) - Uses GridView
class CartView extends StatelessWidget {
  final RecommendationService recommendationService;
  final String selectedCity;
  final Animation<double> fadeAnimation;
  final ValueChanged<Map<String, String>> onAddToCart; // Callback to add item
  final ShoppingCardBuilder shoppingCardBuilder; // Function to build shopping card

  const CartView({
    Key? key,
    required this.recommendationService,
    required this.selectedCity,
    required this.fadeAnimation,
    required this.onAddToCart,
    required this.shoppingCardBuilder, // Require the shopping card builder
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const categoryKey = 'shopping'; // Use 'shopping' for the service call

    return FutureBuilder<List<Map<String, String>>>(
      // Fetch data from the 'products' table via the service
      future: recommendationService.fetchRecommendations(categoryKey, city: selectedCity),
      // future: AppConfig.enableMockData
      //     ? Future.value(recommendationService.getMockRecommendations(categoryKey, city: selectedCity))
      //     : recommendationService.fetchRecommendations(categoryKey, city: selectedCity), // Hypothetical API
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading items: \${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text('No items found for \$selectedCity in the \$categoryKey category.'),
          );
        }

        final recommendations = snapshot.data!;

        return FadeTransition(
          opacity: fadeAnimation,
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              final recommendation = recommendations[index];
              // Use the passed shoppingCardBuilder function
              return shoppingCardBuilder(context, recommendation, onAddToCart);
            },
          ),
        );
      },
    );
  }
}
