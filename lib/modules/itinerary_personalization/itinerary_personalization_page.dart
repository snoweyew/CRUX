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
    if (_isGenerating) return;
    
    setState(() {
      _isGenerating = true;
    });

    try {
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

      try {
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
          try {
            final responseData = jsonDecode(response.body) as Map<String, dynamic>;
            print('DEBUG: Successfully decoded JSON: $responseData');
            
            // Add preferences to the response data
            responseData['food_experiences'] = _preferences.foodPreference;
            responseData['attractions'] = _preferences.attractionsPreference;
            responseData['cultural_experiences'] = _preferences.experiencesPreference;
            responseData['days'] = _preferences.days;
            
            print('DEBUG: Added preferences to response: $responseData');
            
            final itinerary = ItineraryModel.fromJson(responseData);
            print('DEBUG: Successfully created ItineraryModel');
            
            setState(() {
              _generatedItinerary = itinerary;
              _isGenerating = false;
            });
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Itinerary generated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            
            HapticFeedback.lightImpact();
          } catch (e) {
            print('DEBUG: Error parsing response: $e');
            throw Exception('Failed to parse server response: $e');
          }
        } else {
          print('DEBUG: Server returned error status: ${response.statusCode}');
          throw HttpException('Server returned status code: ${response.statusCode}');
        }
      } catch (e) {
        print('DEBUG: Network error: $e');
        throw Exception('Network error: $e');
      }
    } catch (e) {
      print('DEBUG: Final error catch: $e');
      if (!mounted) return;
      
      setState(() {
        _isGenerating = false;
      });
        
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
        child: SingleChildScrollView(
                child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${widget.user.name}!',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Let\'s plan your ${widget.user.selectedCity} adventure',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 24),
      _buildPreferenceSlider(
        title: 'Food Experiences',
        value: _preferences.foodPreference.toDouble(),
        max: 5,
        onChanged: (value) {
          setState(() {
            _preferences = _preferences.copyWith(
              foodPreference: value.round(),
            );
          });
        },
      ),
                      const SizedBox(height: 16),
      _buildPreferenceSlider(
        title: 'Attractions',
        value: _preferences.attractionsPreference.toDouble(),
        max: 3,
        onChanged: (value) {
          setState(() {
            _preferences = _preferences.copyWith(
              attractionsPreference: value.round(),
            );
          });
        },
      ),
                      const SizedBox(height: 16),
      _buildPreferenceSlider(
        title: 'Cultural Experiences',
        value: _preferences.experiencesPreference.toDouble(),
        max: 2,
        onChanged: (value) {
          setState(() {
            _preferences = _preferences.copyWith(
              experiencesPreference: value.round(),
            );
          });
        },
      ),
                      const SizedBox(height: 16),
      _buildPreferenceSlider(
                        title: 'Days',
        value: _preferences.days.toDouble(),
        min: 1,
        max: 3,
        onChanged: (value) {
          setState(() {
            _preferences = _preferences.copyWith(
              days: value.round(),
            );
          });
        },
                      ),
                      if (_generatedItinerary != null) ...[
                        const SizedBox(height: 32),
                        Text(
                          'Your ${_generatedItinerary!.location} Itinerary',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          'Generated on ${_generatedItinerary!.generatedAt.toString()}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        ..._generatedItinerary!.days.map((day) => Card(
                          margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Day ${day.dayNumber}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                                      _buildDayActivities(day),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isGenerating ? null : _generateItinerary,
                      child: _isGenerating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Generate Itinerary'),
                    ),
                  ),
                  if (_generatedItinerary != null) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () {
                        widget.navigationService.navigateTo(
                          '/recommendation',
                          arguments: {
                            'user': widget.user,
                            'itinerary': _generatedItinerary,
                          },
                        );
                      },
                      child: const Text('View Recommendations'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceSlider({
    required String title,
    required double value,
    double min = 0,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
      children: [
        Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: (max - min).round(),
                label: value.round().toString(),
                onChanged: onChanged,
              ),
            ),
            SizedBox(
              width: 50,
              child: Text(
                value.round().toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                      fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDayActivities(DayPlan day) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...['MORNING', 'NOON', 'AFTERNOON', 'EVENING'].map((timeSlot) => 
          _buildTimeSlotSection(timeSlot, day)
        ),
      ],
    );
  }

  Widget _buildTimeSlotSection(String timeSlot, DayPlan day) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                Text(
          timeSlot,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (day.schedule[timeSlot]!.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'No activities scheduled',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          )
        else
          ...day.schedule[timeSlot]!.map((activity) => _buildActivityCard(activity)),
      ],
    );
  }

  Widget _buildActivityCard(Activity activity) {
    IconData icon;
    Color color;

    // More specific and meaningful icons for each type
    switch (activity.type.toLowerCase()) {
      case 'food':
        // Food/restaurant icon
        icon = Icons.restaurant;
        color = Colors.orangeAccent;
        break;
      case 'attraction':
        // Camera/tourist attraction icon
        icon = Icons.photo_camera;
        color = Colors.lightBlue;
        break;
      case 'experience':
        // Cultural/experience icon
        icon = Icons.celebration;
        color = Colors.purpleAccent;
        break;
      default:
        icon = Icons.place;
        color = Colors.grey;
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          activity.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const SizedBox(height: 6),
                Row(
                  children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                    activity.address,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                      ),
                    ),
                  ],
                ),
            if (activity.description != null) ...[
                const SizedBox(height: 4),
                Text(
                activity.description!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
              ],
            ),
      ),
    );
  }
}