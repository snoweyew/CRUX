import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/models/user_model.dart';
import '../../shared/models/preference_model.dart';
import '../../shared/services/navigation_service.dart';
import '../../shared/services/mock_data_service.dart';
import '../../shared/services/http_service.dart';
import 'itinerary_model.dart';
import 'package:http/http.dart' as http;

class ItineraryPersonalizationPage extends StatefulWidget {
  final UserModel user;
  final NavigationService navigationService;
  final MockDataService mockDataService;
  final HttpService httpService;

  const ItineraryPersonalizationPage({
    Key? key,
    required this.user,
    required this.navigationService,
    required this.mockDataService,
    required this.httpService,
  }) : super(key: key);

  @override
  State<ItineraryPersonalizationPage> createState() => _ItineraryPersonalizationPageState();
}

class _ItineraryPersonalizationPageState extends State<ItineraryPersonalizationPage> with SingleTickerProviderStateMixin {
  late PreferenceModel _preferences;
  bool _isGenerating = false;
  ItineraryModel? _generatedItinerary;
  
  // Animation controllers for page transitions and micro-interactions
  late AnimationController _pageController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _preferences = PreferenceModel.initial();
    
    // Initialize animations
    _pageController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pageController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _pageController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));
    
    // Ensure we start with preferences UI
    _generatedItinerary = null;
    _isGenerating = false;
    
    // Start entrance animation after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
    _pageController.forward();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _generateItinerary() async {
    // Provide haptic feedback before starting generation
    HapticFeedback.mediumImpact();

    setState(() {
      _isGenerating = true;
    });

    try {
      // Simulate network delay for better UX
      await Future.delayed(const Duration(milliseconds: 500));

      // --- Start of API Call Logic (Modified from original) ---
      final queryParams = {
        'location': widget.user.selectedCity ?? 'Kuching',
        'food_experiences': _preferences.foodPreference.toString(),
        'attractions': _preferences.attractionsPreference.toString(),
        'cultural_experiences': _preferences.experiencesPreference.toString(),
        'days': _preferences.days.toString(),
        'user_name': widget.user.name ?? 'Guest',
        'user_email': widget.user.email ?? 'guest@example.com',
        'user_role': widget.user.role ?? 'tourist',
      };

      print('DEBUG: Starting API call');
      print('DEBUG: User data: ${widget.user.toJson()}');
      print('DEBUG: Preferences: ${_preferences.toJson()}');
      print('DEBUG: API URL base: ${widget.httpService.baseUrl}');

      final uri = Uri.parse('${widget.httpService.baseUrl}/generate_itinerary_json')
          .replace(queryParameters: queryParams);

      print('DEBUG: Full request URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Request timed out after 30 seconds'),
      );

      print('DEBUG: Response received');
      print('DEBUG: Status code: ${response.statusCode}');
      print('DEBUG: Response headers: ${response.headers}');
      print('DEBUG: Response body: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print('DEBUG: Successfully decoded JSON: $responseData');

        // Add preferences to the response data (as in original)
        responseData['food_experiences'] = _preferences.foodPreference;
        responseData['attractions'] = _preferences.attractionsPreference;
        responseData['cultural_experiences'] = _preferences.experiencesPreference;
        responseData['days'] = _preferences.days;

        print('DEBUG: Added preferences to response: $responseData');

        final itinerary = ItineraryModel.fromJson(responseData);
        print('DEBUG: Successfully created ItineraryModel');
        // --- End of API Call Logic ---

        if (mounted) {
          setState(() {
            _generatedItinerary = itinerary;
            _isGenerating = false;
          });

          // Reset and play animation for new itinerary
          _pageController.reset();
          _pageController.forward();

          // Success feedback
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Itinerary generated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
         print('DEBUG: Server returned error status: ${response.statusCode}');
         throw HttpException('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Final error catch: $e');
      if (mounted) {
        // Error feedback
        HapticFeedback.vibrate();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to generate itinerary: ${e.toString()}')),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade700,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 5), // Added duration
          ),
        );
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define our monochromatic colors
    final primaryColor = const Color(0xFF2C2C2C); // Dark grey/almost black
    final primaryLightColor = const Color(0xFFF5F5F5); // Very light grey
    final primaryDarkColor = const Color(0xFF1A1A1A); // Darker grey
    final accentColor = const Color(0xFF757575); // Medium grey

    return Scaffold(
      body: AnimatedContainer( // Changed from simple Scaffold body
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryLightColor,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: _generatedItinerary == null
              ? _buildPreferencesUI(primaryColor, primaryLightColor, primaryDarkColor, accentColor)
              : _buildItineraryUI(), // Conditional UI based on _generatedItinerary
        ),
      ),
    );
  }

  // New method for Preferences UI
  Widget _buildPreferencesUI(Color primaryColor, Color primaryLightColor, Color primaryDarkColor, Color accentColor) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: child,
          );
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced welcome header with animation
              _buildAnimatedHeader(),
              const SizedBox(height: 32),

              // Preference sliders with enhanced visuals
              ..._buildPreferenceSliders(),
              const SizedBox(height: 40),

              // Enhanced summary card
              _buildEnhancedSummaryCard(),
              const SizedBox(height: 32),

              // Enhanced action buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // New method for Animated Header
  Widget _buildAnimatedHeader() {
    final primaryColor = const Color(0xFF2C2C2C);
    final primaryLightColor = const Color(0xFFF5F5F5);

    return Hero(
      tag: 'welcome_header',
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.transparent, // Changed from white
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: primaryColor,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${widget.user.name}!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      Text(
                        'Let\'s plan your ${widget.user.selectedCity} adventure', // Escaped the apostrophe
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // New method to build list of sliders
  List<Widget> _buildPreferenceSliders() {
    return [
      _buildPreferenceSlider(
        title: 'Food Experiences',
        description: 'How many food experiences would you like per day?',
        icon: Icons.restaurant,
        value: _preferences.foodPreference.toDouble(),
        min: 0,
        max: 5,
        onChanged: (value) {
          HapticFeedback.selectionClick();
          setState(() {
            _preferences = _preferences.copyWith(
              foodPreference: value.round(),
            );
          });
        },
      ),
      const SizedBox(height: 24),
      _buildPreferenceSlider(
        title: 'Attractions',
        description: 'How many attractions would you like to visit per day?',
        icon: Icons.photo_camera,
        value: _preferences.attractionsPreference.toDouble(),
        min: 0,
        max: 3,
        onChanged: (value) {
          HapticFeedback.selectionClick();
          setState(() {
            _preferences = _preferences.copyWith(
              attractionsPreference: value.round(),
            );
          });
        },
      ),
      const SizedBox(height: 24),
      _buildPreferenceSlider(
        title: 'Cultural Experiences',
        description: 'How many cultural experiences would you like per day?',
        icon: Icons.theater_comedy,
        value: _preferences.experiencesPreference.toDouble(),
        min: 0,
        max: 2,
        onChanged: (value) {
          HapticFeedback.selectionClick();
          setState(() {
            _preferences = _preferences.copyWith(
              experiencesPreference: value.round(),
            );
          });
        },
      ),
      const SizedBox(height: 24),
      _buildPreferenceSlider(
        title: 'Trip Duration',
        description: 'How many days will you be staying?',
        icon: Icons.calendar_today,
        value: _preferences.days.toDouble(),
        min: 1,
        max: 3,
        onChanged: (value) {
          HapticFeedback.selectionClick();
          setState(() {
            _preferences = _preferences.copyWith(
              days: value.round(),
            );
          });
        },
        valueDisplay: (value) => '${value.round()} ${value.round() == 1 ? 'day' : 'days'}',
      ),
    ];
  }

  // Modified _buildPreferenceSlider
  Widget _buildPreferenceSlider({
    required String title,
    required String description, // Added description
    required IconData icon, // Added icon
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    String Function(double)? valueDisplay, // Added valueDisplay
  }) {
    final primaryColor = const Color(0xFF2C2C2C);
    final accentColor = const Color(0xFF757575);

    return TweenAnimationBuilder<double>( // Added animation
      duration: const Duration(milliseconds: 200),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity,
          child: child,
        );
      },
      child: Container( // Wrapped in styled Container
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row( // Added Icon and Title/Description Row
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: primaryColor, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox( // Custom Slider visualization
              height: 32,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF2C2C2C),
                        inactiveTrackColor: Colors.grey.shade200,
                        thumbColor: Colors.transparent,
                        overlayColor: Colors.transparent,
                        trackHeight: 18.0,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 0,
                          pressedElevation: 0,
                        ),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
                        tickMarkShape: SliderTickMarkShape.noTickMark,
                        showValueIndicator: ShowValueIndicator.never,
                      ),
                      child: Slider(
                        value: value,
                        min: title == 'Trip Duration' ? 1 : min, // Adjusted min for duration
                        max: max,
                        divisions: max.toInt() - (title == 'Trip Duration' ? 1 : 0), // Adjusted divisions
                        onChanged: onChanged,
                      ),
                    ),
                  ),
                  Positioned.fill( // Overlay circles
                    child: IgnorePointer(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            (max - (title == 'Trip Duration' ? 1 : 0)).toInt() + 1,
                            (index) {
                              final actualValue = index + (title == 'Trip Duration' ? 1 : 0);
                              final isSelected = value.round() >= actualValue;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? const Color(0xFF2C2C2C) : Colors.grey.shade200,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2C2C2C).withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOutCubic,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected ? Colors.white : Colors.grey.shade600,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    child: Text(actualValue.toString()),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8), // Removed value text display
          ],
        ),
      ),
    );
  }

  // New method for Summary Card
  Widget _buildEnhancedSummaryCard() {
    final primaryColor = const Color(0xFF2C2C2C);
    final accentColor = const Color(0xFF757575);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Itinerary Summary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          _buildSummaryItem(
            icon: Icons.location_city,
            title: 'Destination',
            value: widget.user.selectedCity ?? 'N/A', // Handle null city
            primaryColor: primaryColor,
            accentColor: accentColor,
          ),
          Divider(color: Colors.grey.shade200, height: 24),
          _buildSummaryItem(
            icon: Icons.calendar_today,
            title: 'Duration',
            value: '${_preferences.days} ${_preferences.days == 1 ? 'day' : 'days'}',
            primaryColor: primaryColor,
            accentColor: accentColor,
          ),
          Divider(color: Colors.grey.shade200, height: 24),
          _buildSummaryItem(
            icon: Icons.restaurant,
            title: 'Food Experiences',
            value: '${_preferences.foodPreference} per day',
            primaryColor: primaryColor,
            accentColor: accentColor,
          ),
          Divider(color: Colors.grey.shade200, height: 24),
          _buildSummaryItem(
            icon: Icons.photo_camera,
            title: 'Attractions',
            value: '${_preferences.attractionsPreference} per day',
            primaryColor: primaryColor,
            accentColor: accentColor,
          ),
          Divider(color: Colors.grey.shade200, height: 24),
          _buildSummaryItem(
            icon: Icons.theater_comedy,
            title: 'Cultural Experiences',
            value: '${_preferences.experiencesPreference} per day',
            primaryColor: primaryColor,
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  // New helper for Summary Item
  Widget _buildSummaryItem({
    required IconData icon,
    required String title,
    required String value,
    required Color primaryColor,
    required Color accentColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: accentColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: accentColor,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
      ],
    );
  }

  // New method for Action Buttons
  Widget _buildActionButtons() {
    final primaryColor = const Color(0xFF2C2C2C);
    final accentColor = const Color(0xFF757575);

    return Column( // Changed Row to Column
      children: [
        SizedBox( // Ensure Generate button takes full width
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isGenerating ? null : _generateItinerary,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.2),
            ),
            child: _isGenerating
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Generate Itinerary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16), // Added space between buttons
        SizedBox( // Ensure View Recommendations button takes full width
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              widget.navigationService.navigateTo(
                '/recommendation',
                arguments: {
                  'user': widget.user,
                  'itinerary': _generatedItinerary, // Pass null if not generated yet
                },
              );
            },
            icon: Icon(Icons.recommend, color: primaryColor),
            label: Text(
              'View Recommendations', // Removed line break
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16, // Adjusted font size
                color: primaryColor,
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: 16, // Adjusted padding
                horizontal: 16,
              ),
              backgroundColor: Colors.white,
              foregroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: primaryColor,
                  width: 2,
                ),
              ),
              elevation: 2, // Added slight elevation for consistency
            ),
          ),
        ),
      ],
    );
  }

  // New method for Itinerary UI
  Widget _buildItineraryUI() {
    final primaryColor = const Color(0xFF2C2C2C);

    // Ensure itinerary is not null before building this UI
    if (_generatedItinerary == null) {
      return const Center(child: Text("Error: Itinerary not available."));
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your ${widget.user.selectedCity ?? 'Selected City'} Itinerary', // Handle null city
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  // Use generatedAt from the model
                  'Generated on ${_generatedItinerary!.generatedAt.day}/${_generatedItinerary!.generatedAt.month}/${_generatedItinerary!.generatedAt.year}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                ..._generatedItinerary!.days.map((day) => _buildDayCard(day)),
              ],
            ),
          ),
        ),
        // Bottom buttons
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 50, // Adjusted height
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to the recommendation page
                    widget.navigationService.navigateTo(
                      '/recommendation',
                      arguments: {
                        'user': widget.user,
                        'itinerary': _generatedItinerary,
                      },
                    );
                  },
                  icon: const Icon(Icons.recommend, color: Colors.white), // Added color
                  label: const Text('View Recommendations', style: TextStyle(color: Colors.white)), // Added color
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Match other buttons
                    ),
                    backgroundColor: primaryColor, // Use primary color
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _generatedItinerary = null; // Go back to preferences
                          _pageController.reset(); // Reset animation
                          _pageController.forward(); // Play entrance animation again
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // Match other buttons
                        ),
                        side: BorderSide(color: primaryColor, width: 2), // Match border
                      ),
                      child: Text('Customize Again', style: TextStyle(color: primaryColor)), // Match color
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // In a real app, this would save the itinerary
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Itinerary saved!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // Match other buttons
                        ),
                        backgroundColor: primaryColor, // Match background
                      ),
                      child: const Text('Save Itinerary', style: TextStyle(color: Colors.white)), // Match color
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // New method for Day Card
  Widget _buildDayCard(DayPlan day) {
    final primaryColor = const Color(0xFF2C2C2C); // Define primary color

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor, // Use primary color
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text(
                  'Day ${day.dayNumber}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Activities
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              // Use the schedule map from the model
              children: day.schedule.entries.expand((entry) {
                 final timeSlot = entry.key;
                 final activities = entry.value;
                 if (activities.isEmpty) return <Widget>[]; // Skip empty slots

                 return [
                   Padding(
                     padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                     child: Text(
                       timeSlot,
                       style: TextStyle(
                         fontSize: 16,
                         fontWeight: FontWeight.bold,
                         color: Colors.grey.shade700,
                       ),
                     ),
                   ),
                   ...activities.map((activity) => _buildActivityItem(activity, timeSlot)),
                 ];
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // New method for Activity Item
  Widget _buildActivityItem(Activity activity, String timeSlot) { // Added timeSlot parameter
    IconData activityIcon;
    Color activityColor;
    String? boxText; // Optional text below icon

    switch (activity.type.toLowerCase()) { // Use lowercase for safety
      case 'food':
        activityIcon = Icons.restaurant;
        activityColor = Colors.orange;
        break;
      case 'attraction':
        activityIcon = Icons.photo_camera;
        activityColor = Colors.blue;
        break;
      case 'experience':
        activityIcon = Icons.theater_comedy; // Changed icon
        activityColor = Colors.purple;
        boxText = "Explore Sarawak"; // Example text
        break;
      default:
        activityIcon = Icons.place;
        activityColor = Colors.green; // Changed default color
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column( // Wrap icon and optional text
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: activityColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  activityIcon,
                  color: activityColor,
                ),
              ),
              if (boxText != null) // Conditionally add text box
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: activityColor.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    boxText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row( // Activity Name and Time Slot
                  children: [
                    Expanded(
                      child: Text(
                        activity.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text( // Display time slot here
                      timeSlot,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (activity.description != null && activity.description!.isNotEmpty) // Check description
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      activity.description!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                // const SizedBox(height: 4), // Removed extra space
                Row( // Location
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        activity.address, // Use address field from model
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}