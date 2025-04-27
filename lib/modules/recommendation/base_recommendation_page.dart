import 'package:flutter/material.dart';
import '../../shared/models/user_model.dart';
import '../../shared/services/navigation_service.dart';
import '../../shared/services/mock_data_service.dart';
import '../../shared/services/recommendation_service.dart';
import '../../shared/config/app_config.dart';
import '../itinerary_personalization/itinerary_model.dart';
import 'recommendation_pages.dart' as pages;

// Base class for recommendation pages
abstract class BaseRecommendationPage extends StatefulWidget {
  final UserModel user;
  final NavigationService navigationService;
  final MockDataService mockDataService;
  final ItineraryModel? itinerary;
  final RecommendationService recommendationService;

  const BaseRecommendationPage({
    Key? key,
    required this.user,
    required this.navigationService,
    required this.mockDataService,
    required this.itinerary,
    required this.recommendationService,
  }) : super(key: key);
  
  // Factory method to create the appropriate page based on index
  static Widget createPage(
    int index,
    UserModel user,
    NavigationService navigationService,
    MockDataService mockDataService,
    ItineraryModel? itinerary,
    RecommendationService recommendationService,
    BuildContext context,
  ) {
    // Use the factory method from recommendation_pages.dart
    return pages.RecommendationPageFactory.createPage(
      index, user, navigationService, mockDataService, itinerary, recommendationService, context
    );
  }
}

// Base state class for recommendation pages
abstract class BaseRecommendationPageState<T extends BaseRecommendationPage> extends State<T> with SingleTickerProviderStateMixin {
  // Animation controller for page transitions
  late AnimationController animationController;
  late Animation<double> fadeAnimation;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
    );
    animationController.forward();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }
  
  // Common methods that can be overridden by subclasses
  String getPageTitle();
  IconData getPageIcon();
  Future<List<Map<String, String>>> getRecommendations();
  
  // Helper method to navigate to another category
  void navigateToCategory(BuildContext context, int categoryIndex) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => pages.RecommendationPageFactory.createPage(
          categoryIndex,
          widget.user,
          widget.navigationService,
          widget.mockDataService,
          widget.itinerary,
          widget.recommendationService,
          context,
        ),
      ),
    );
  }
  
  // Common UI elements
  Widget buildNavItem(int index, int selectedIndex) {
    final categories = ['Events', 'Food', 'Experiences', 'Attractions', 'Shopping'];
    final categoryIcons = [
      Icons.event,
      Icons.restaurant,
      Icons.theater_comedy,
      Icons.photo_camera,
      Icons.shopping_bag,
    ];
    
    final isSelected = selectedIndex == index;
    
    return GestureDetector(
      onTap: () {
        if (selectedIndex != index) {
          navigateToCategory(context, index);
        }
      },
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              categoryIcons[index],
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              categories[index],
              style: TextStyle(
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: const BoxDecoration(
        color: Color(0xFF2C2C2C),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(getPageIcon(), color: Colors.white, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              getPageTitle(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget buildBottomNavBar(int selectedIndex) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              5, // 5 categories
              (index) => buildNavItem(index, selectedIndex),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget buildRecommendationCard(Map<String, String> recommendation) {
    final screenHeight = MediaQuery.of(context).size.height;
    final double cardHeight = screenHeight * 0.22; // Adjusted to 22% of screen height
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // Show detailed view (to be implemented)
        },
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: cardHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section (3/4)
              Expanded(
                flex: 7, // Adjusted ratio
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    image: DecorationImage(
                      image: AssetImage(getCategoryImage()),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              // Text section (1/4)
              Expanded(
                flex: 3, // Adjusted ratio
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recommendation['name']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              recommendation['location']!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget buildRecommendationsList() {
    return FutureBuilder<List<Map<String, String>>>(
      future: getRecommendations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final recommendations = snapshot.data ?? [];
        
        return FadeTransition(
          opacity: fadeAnimation,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              final recommendation = recommendations[index];
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 200 + (index * 100)),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 50 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: buildRecommendationCard(recommendation),
              );
            },
          ),
        );
      },
    );
  }
  
  String getCategoryImage() {
    // Implement in each subclass
    return 'assets/images/default_placeholder.jpg';
  }
  
  @override
  Widget build(BuildContext context) {
    int categoryIndex = getCategoryIndex();
    
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            buildAppBar(),
            const SizedBox(height: 8),
            Expanded(
              child: buildRecommendationsList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: buildBottomNavBar(categoryIndex),
    );
  }
  
  int getCategoryIndex() {
    // To be implemented by subclasses
    return 0;
  }
} 