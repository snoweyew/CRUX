import 'package:flutter/material.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/services/navigation_service.dart';
import '../../shared/services/mock_data_service.dart';
import '../../shared/models/user_model.dart';

class City {
  final String name;
  final String imageUrl;
  final String description;

  City({
    required this.name,
    required this.imageUrl,
    required this.description,
  });
}

class CitySelectionPage extends StatefulWidget {
  final AuthService authService;
  final NavigationService navigationService;
  final MockDataService mockDataService;
  final UserModel tempUser;

  const CitySelectionPage({
    Key? key,
    required this.authService,
    required this.navigationService,
    required this.mockDataService,
    required this.tempUser,
  }) : super(key: key);

  @override
  State<CitySelectionPage> createState() => _CitySelectionPageState();
}

class _CitySelectionPageState extends State<CitySelectionPage> {
  // Selected city
  City? _selectedCity;
  
  // Current page index
  int _currentPage = 0;
  
  // Page controller
  final PageController _pageController = PageController();
  
  // List of available cities
  late List<City> _cities;
  
  // Loading state
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize cities from mock data
    final cityNames = widget.mockDataService.getSarawakCities();
    _cities = cityNames.map((name) {
      String description = '';
      String imageUrl = '';
      
      switch (name) {
        case 'Kuching':
          description = 'Capital city of Sarawak with rich cultural heritage';
          imageUrl = 'https://images.pexels.com/photos/4542639/pexels-photo-4542639.jpeg';
          break;
        case 'Miri':
          description = 'Resort city with beautiful beaches and national parks';
          imageUrl = 'https://images.pexels.com/photos/22776427/pexels-photo-22776427/free-photo-of-boats-on-beach-in-summer.jpeg';
          break;
        case 'Sibu':
          description = 'Commercial center known for its markets and food';
          imageUrl = 'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/10/a0/05/60/screenshot-2017-09-11.jpg';
          break;
        case 'Bintulu':
          description = 'Industrial city with natural attractions';
          imageUrl = 'https://apicms.thestar.com.my/uploads/images/2024/11/18/thumbs/700/3022072.webp';
          break;
        default:
          description = 'A beautiful city in Sarawak';
          imageUrl = 'https://images.pexels.com/photos/2161467/pexels-photo-2161467.jpeg';
      }
      
      return City(
        name: name,
        imageUrl: imageUrl,
        description: description,
      );
    }).toList();
    
    // Set the initial selected city
    if (_cities.isNotEmpty) {
      _selectedCity = _cities[0];
    }
    
    // Add listener to page controller
    _pageController.addListener(() {
      int page = _pageController.page?.round() ?? 0;
      if (_currentPage != page && page < _cities.length) {
        setState(() {
          _currentPage = page;
          _selectedCity = _cities[page];
        });
      }
    });
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Handle city selection
  Future<void> _handleCitySelection() async {
    if (_selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a city')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Update the user with the selected city
      final user = widget.tempUser.copyWith(
        selectedCity: _selectedCity!.name,
      );
      
      // Navigate to visitor type selection page
      widget.navigationService.navigateTo(
        '/visitor_type',
        arguments: user,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen PageView for city cards
          PageView.builder(
            controller: _pageController,
            itemCount: _cities.length,
            itemBuilder: (context, index) {
              final city = _cities[index];
              return _buildCityCard(city, index == _currentPage);
            },
          ),
          
          // Content overlays wrapped in IgnorePointer
          IgnorePointer(
            child: Stack(
              children: [
                // Overlay gradient at the top
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 200,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Overlay gradient at the bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 400,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.9),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content overlay with selective interaction
          SafeArea(
            child: Column(
              children: [
                // Header (non-interactive)
                IgnorePointer(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const Text(
                          'Select Your Destination',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Swipe to explore cities in Sarawak',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // City name and description (non-interactive)
                IgnorePointer(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      children: [
                        Text(
                          _selectedCity?.name ?? '',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedCity?.description ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Interactive elements (button and indicators)
                Padding(
                  padding: const EdgeInsets.fromLTRB(32.0, 32.0, 32.0, 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleCitySelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C2C2C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: Colors.black.withOpacity(0.2),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : const Text(
                              'Continue to Itinerary',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),

                // Page indicator (non-interactive)
                IgnorePointer(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 32.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _cities.length,
                        (index) => _buildPageIndicator(index == _currentPage),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build a full-screen city card
  Widget _buildCityCard(City city, bool isActive) {
    return Hero(
      tag: 'city_${city.name}',
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[800],
          image: DecorationImage(
            image: NetworkImage(city.imageUrl),
            fit: BoxFit.cover,
            onError: (exception, stackTrace) {
              print('Error loading image for ${city.name}: $exception');
            },
          ),
        ),
      ),
    );
  }
  
  /// Build a page indicator dot
  Widget _buildPageIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: isActive ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF2C2C2C) : Colors.white,
        border: Border.all(
          color: const Color(0xFF2C2C2C),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }
} 