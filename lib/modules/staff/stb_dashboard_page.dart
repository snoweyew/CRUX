import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Add Supabase import
import '../../shared/models/user_model.dart';
// import '../../shared/services/mock_data_service.dart'; // Remove mock data service import
import '../../shared/services/supabase_submission_service.dart'; 
import 'widgets/visitor_stats_section.dart';
import 'widgets/event_management_section.dart';
import 'widgets/submission_section.dart';
import 'product_management_page.dart'; // Import the new product management page
import 'cart_item_input_page.dart'; // Import the cart item input page

class TouristStats {
  final String city;
  final int visitorCount; // Represents total_visitors from Supabase
  final int malaysianVisitors; // Add field for malaysian_visitors
  final int foreignVisitors; // Add field for foreign_visitors
  final Map<String, int> visitorsByCountry; // Represents country_counts from Supabase
  final List<Order> orders; // Keep for potential future use or remove if unused
  final Map<String, double> satisfactionRatings; // Keep for potential future use or remove if unused
  final List<Complaint> complaints; // Keep for potential future use or remove if unused
  final List<Event> events; // Keep for potential future use or remove if unused
  final List<LocalSubmission> pendingSubmissions; // Keep for potential future use or remove if unused

  TouristStats({
    required this.city,
    required this.visitorCount,
    required this.malaysianVisitors, // Add to constructor
    required this.foreignVisitors, // Add to constructor
    required this.visitorsByCountry,
    required this.orders,
    required this.satisfactionRatings,
    required this.complaints,
    required this.events,
    required this.pendingSubmissions,
  });

  // Factory constructor to create TouristStats from Supabase data
  factory TouristStats.fromSupabase(String city, Map<String, dynamic> data) {
    final countryCountsData = data['country_counts'] as Map<String, dynamic>? ?? {};
    final visitorsByCountry = countryCountsData.map((key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0));

    return TouristStats(
      city: city,
      visitorCount: (data['total_visitors'] as num?)?.toInt() ?? 0,
      malaysianVisitors: (data['malaysian_visitors'] as num?)?.toInt() ?? 0,
      foreignVisitors: (data['foreign_visitors'] as num?)?.toInt() ?? 0,
      visitorsByCountry: visitorsByCountry,
      // Provide default empty lists/maps for unused fields for now
      orders: [], 
      satisfactionRatings: {}, 
      complaints: [], 
      events: [], 
      pendingSubmissions: [], 
    );
  }

  // Factory constructor for an empty state
  factory TouristStats.empty(String city) {
    return TouristStats(
      city: city,
      visitorCount: 0,
      malaysianVisitors: 0,
      foreignVisitors: 0,
      visitorsByCountry: {},
      orders: [],
      satisfactionRatings: {},
      complaints: [],
      events: [],
      pendingSubmissions: [],
    );
  }
}

// ... existing Order, Complaint, Event, LocalSubmission classes ...
// (Keep these classes for now, even if not populated from Supabase yet)
class Order {
  final String touristName;
  final String item;
  final double amount;
  final String airport;
  final DateTime date;

  Order({
    required this.touristName,
    required this.item,
    required this.amount,
    required this.airport,
    required this.date,
  });
}

class Complaint {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String status;
  final String category;

  Complaint({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.status,
    required this.category,
  });
}

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String venue;
  final String category;
  final String status;
  final String? imageUrl;
  final String? city;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.venue,
    required this.category,
    required this.status,
    this.imageUrl,
    this.city,
  });
}

class LocalSubmission {
  final String id;
  final String title;
  final String description;
  final String submitterName;
  final DateTime date;
  final String status;

  LocalSubmission({
    required this.id,
    required this.title,
    required this.description,
    required this.submitterName,
    required this.date,
    required this.status,
  });
}


class STBDashboardPage extends StatefulWidget {
  final UserModel user;
  // final MockDataService mockDataService; // Remove mockDataService
  final SupabaseSubmissionService submissionService; 

  const STBDashboardPage({
    Key? key,
    required this.user,
    // required this.mockDataService, // Remove mockDataService
    required this.submissionService, 
  }) : super(key: key);

  @override
  State<STBDashboardPage> createState() => _STBDashboardPageState();
}

class _STBDashboardPageState extends State<STBDashboardPage> {
  int _selectedIndex = 0;
  List<String> cities = []; // Keep list of cities
  // Map<String, TouristStats> cityStats = {}; // Remove mock stats map
  TouristStats? _currentStats; // State variable for fetched stats
  bool isLoading = true; // Keep loading state
  String? selectedCity;
  String selectedTimeFrame = 'Monthly'; // Keep filters if needed
  String selectedVisitorType = 'All'; // Keep filters if needed
  
  final List<String> timeFrames = ['Monthly', 'Quarterly', 'Yearly'];
  final List<String> visitorTypes = ['All', 'Local', 'Foreign'];

  final _supabase = Supabase.instance.client; // Add Supabase client instance

  @override
  void initState() {
    super.initState();
    // TODO: Fetch the list of cities dynamically if possible, or keep static list
    cities = ['Kuching', 'Miri', 'Sibu', 'Bintulu']; // Example static list
    selectedCity = cities.isNotEmpty ? cities[0] : null;
    // _loadMockData(); // Remove call to load mock data
    if (selectedCity != null) {
      _fetchVisitorStats(selectedCity!); // Fetch initial data
    } else {
       setState(() {
         isLoading = false; // No city selected, stop loading
       });
    }
  }

  // Remove _loadMockData method
  // void _loadMockData() { ... }

  // Remove _generateMockStats method
  // Map<String, TouristStats> _generateMockStats() { ... }

  // Add method to fetch data from Supabase
  Future<void> _fetchVisitorStats(String city) async {
    if (!mounted) return; // Check if widget is still in the tree
    setState(() {
      isLoading = true; // Start loading
      _currentStats = null; // Clear previous stats
    });

    try {
      final response = await _supabase
          .from('visitor_stats')
          .select()
          .eq('city', city)
          .maybeSingle();

      if (!mounted) return; // Check again after await

      if (response != null) {
        final stats = TouristStats.fromSupabase(city, response as Map<String, dynamic>);
         setState(() {
           _currentStats = stats;
           isLoading = false;
         });
      } else {
        // No data found for the city, create an empty state
        setState(() {
          _currentStats = TouristStats.empty(city);
          isLoading = false;
        });
        print('No visitor stats found for city: $city');
      }
    } catch (e) {
       if (!mounted) return; // Check again after await
       print('Error fetching visitor stats for $city: $e');
       setState(() {
         _currentStats = TouristStats.empty(city); // Show empty state on error
         isLoading = false;
         // Optionally show an error message to the user
         // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading stats: ${e.toString()}')));
       });
    }
  }
  

  @override
  Widget build(BuildContext context) {
    // ... existing AppBar ...
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2C2C),
        elevation: 0,
        title: Text(
          _getTitle(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column( // Keep the main column structure
              children: [
                // Keep header and filters for the 'Visitors' tab
                if (_selectedIndex == 0) ...[
                  _buildHeader(),
                  _buildFilters(), // Keep filters if they are still relevant
                ],
                Expanded(
                  // Use a FutureBuilder or handle loading state before building the page
                  child: _buildPage(), 
                ),
              ],
            ),
      // ... existing BottomNavigationBar ...
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF2C2C2C),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Visitors',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Submissions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_shopping_cart),
            label: 'Add Cart',
          ),
        ],
        onTap: (index) {
          if (index == 3) {
            // Navigate to Cart Item Input page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CartItemInputPage(user: widget.user),
              ),
            );
          } else {
            setState(() {
              _selectedIndex = index;
              // Potentially trigger data fetch if switching to a tab that needs it
              // and data hasn't been loaded yet. (Handled by _buildPage logic)
            });
          }
        },
      ),
    );
  }

  // ... existing _getTitle ...
  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Visitor Statistics';
      case 1:
        return 'Event Management';
      case 2:
        return 'Local Submissions';
      default:
        return 'STB Dashboard';
    }
  }

  Widget _buildPage() {
    // Handle loading state first
    if (isLoading) {
       return const Center(child: CircularProgressIndicator());
    }
    
    // Handle 'Visitors' tab (index 0)
    if (_selectedIndex == 0) {
      if (selectedCity == null) {
        return const Center(child: Text('Please select a city'));
      }
      // Use the fetched _currentStats
      if (_currentStats == null) {
        // This case might happen briefly or if fetching failed silently
        return const Center(child: Text('Loading stats...')); 
      }
      // Pass the fetched stats to VisitorStatsSection
      return VisitorStatsSection(stats: _currentStats!); 
    } 
    // Handle 'Events' tab (index 1) - Needs similar data fetching logic if required
    else if (_selectedIndex == 1) {
       // TODO: Implement data fetching for Events if needed, similar to Visitors
       // For now, might show placeholder or use _currentStats if relevant
       if (selectedCity == null) return const Center(child: Text('Please select a city'));
       if (_currentStats == null) return const Center(child: Text('Loading data...'));
       // Assuming EventManagementSection also uses TouristStats for now
       // You might need a separate fetch or adapt EventManagementSection
       return EventManagementSection(stats: _currentStats!); 
    }
    // Handle 'Submissions' tab (index 2)
    else if (_selectedIndex == 2) {
       // Pass the submissionService from the widget
       return SubmissionSection(submissionService: widget.submissionService);
    }

    // Default fallback
    return const Center(child: Text('Page not found'));
  }

  Widget _buildHeader() {
    // ... (Keep existing header with city dropdown) ...
    return Container(
      color: const Color(0xFF2C2C2C),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          const Icon(Icons.location_city, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedCity,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  style: const TextStyle(
                    color: Color(0xFF2C2C2C),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  items: cities.map((String city) {
                    return DropdownMenuItem<String>(
                      value: city,
                      child: Text(city),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null && newValue != selectedCity) {
                      setState(() {
                        selectedCity = newValue;
                        // Fetch data for the newly selected city
                        _fetchVisitorStats(newValue); 
                      });
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ... existing _buildFilters and _buildFilterDropdown ...
  // (Keep these if the filters are still needed for the fetched data)
  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterDropdown(
              value: selectedTimeFrame,
              items: timeFrames,
              onChanged: (value) {
                if (value != null && value != selectedTimeFrame) { // Check if value changed
                  setState(() {
                    selectedTimeFrame = value;
                    // Re-fetch data for the current city when time frame changes
                    if (selectedCity != null) {
                       _fetchVisitorStats(selectedCity!);
                    }
                  });
                }
              },
              icon: Icons.calendar_today,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildFilterDropdown(
              value: selectedVisitorType,
              items: visitorTypes,
              onChanged: (value) {
                 if (value != null && value != selectedVisitorType) { // Check if value changed
                  setState(() {
                    selectedVisitorType = value;
                    // Re-fetch data for the current city when visitor type changes
                     if (selectedCity != null) {
                       _fetchVisitorStats(selectedCity!);
                     }
                  });
                 }
              },
              icon: Icons.people,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          style: const TextStyle(
            color: Color(0xFF2C2C2C),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Row(
                children: [
                  Icon(icon, size: 16, color: const Color(0xFF2C2C2C)),
                  const SizedBox(width: 8),
                  Text(item),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}