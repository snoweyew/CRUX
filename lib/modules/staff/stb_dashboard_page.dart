import 'package:flutter/material.dart';
import '../../shared/models/user_model.dart';
import '../../shared/services/mock_data_service.dart';
import '../../shared/services/supabase_submission_service.dart'; // Import the service
import 'widgets/visitor_stats_section.dart';
import 'widgets/event_management_section.dart';
import 'widgets/submission_section.dart';

class TouristStats {
  final String city;
  final int visitorCount;
  final Map<String, int> visitorsByCountry;
  final List<Order> orders;
  final Map<String, double> satisfactionRatings;
  final List<Complaint> complaints;
  final List<Event> events;
  final List<LocalSubmission> pendingSubmissions;

  TouristStats({
    required this.city,
    required this.visitorCount,
    required this.visitorsByCountry,
    required this.orders,
    required this.satisfactionRatings,
    required this.complaints,
    required this.events,
    required this.pendingSubmissions,
  });
}

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
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String venue;
  final String category;
  final String status;

  Event({
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.venue,
    required this.category,
    required this.status,
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
  final MockDataService mockDataService;
  final SupabaseSubmissionService submissionService; // Add submissionService

  const STBDashboardPage({
    Key? key,
    required this.user,
    required this.mockDataService,
    required this.submissionService, // Require submissionService
  }) : super(key: key);

  @override
  State<STBDashboardPage> createState() => _STBDashboardPageState();
}

class _STBDashboardPageState extends State<STBDashboardPage> {
  int _selectedIndex = 0;
  List<String> cities = [];
  Map<String, TouristStats> cityStats = {};
  bool isLoading = true;
  String? selectedCity;
  String selectedTimeFrame = 'Monthly';
  String selectedVisitorType = 'All';
  
  final List<String> timeFrames = ['Monthly', 'Quarterly', 'Yearly'];
  final List<String> visitorTypes = ['All', 'Local', 'Foreign'];

  @override
  void initState() {
    super.initState();
    cities = widget.mockDataService.getSarawakCities();
    selectedCity = cities.isNotEmpty ? cities[0] : null;
    _loadMockData();
  }

  void _loadMockData() {
    // Simulate loading data
    Future.delayed(const Duration(seconds: 1), () {
      final mockStats = _generateMockStats();
      if (mounted) { // Add mounted check
        setState(() {
          cityStats = mockStats;
          isLoading = false;
        });
      }
    });
  }

  Map<String, TouristStats> _generateMockStats() {
    final Map<String, TouristStats> stats = {};
    final countries = ['Malaysia', 'Singapore', 'Indonesia', 'China', 'Japan', 'Australia'];
    final airports = ['Kuching International Airport', 'Miri Airport', 'Sibu Airport', 'Bintulu Airport'];
    final items = ['Local Tour Package', 'Hotel Booking', 'Transportation', 'Souvenir Package'];

    for (var city in cities) {
      final visitorCount = 100 + (DateTime.now().millisecondsSinceEpoch % 900);
      final visitorsByCountry = Map.fromEntries(
        countries.map((country) => MapEntry(country, 10 + (DateTime.now().millisecondsSinceEpoch % 90))),
      );

      final orders = List.generate(5, (index) => Order(
        touristName: 'Tourist ${index + 1}',
        item: items[index % items.length],
        amount: 100.0 + (index * 50),
        airport: airports[index % airports.length],
        date: DateTime.now().subtract(Duration(days: index)),
      ));

      final mockEvents = List.generate(3, (index) => Event(
        title: 'Event ${city.substring(0,3)} ${index + 1}',
        description: 'Description for event ${index + 1} in $city',
        startDate: DateTime.now().add(Duration(days: 30 + index * 5)),
        endDate: DateTime.now().add(Duration(days: 32 + index * 5)),
        venue: '$city Convention Center',
        category: 'Festival',
        status: index == 0 ? 'Upcoming' : 'Past',
      ));

      stats[city] = TouristStats(
        city: city,
        visitorCount: visitorCount,
        visitorsByCountry: visitorsByCountry,
        orders: orders,
        satisfactionRatings: {
          'Overall': 4.2 + (city.length % 5) * 0.1,
          'Accommodation': 4.0 + (city.length % 6) * 0.1,
        },
        complaints: [],
        events: mockEvents,
        pendingSubmissions: [], // Keep this empty, data comes from Supabase now
      );
    }

    return stats;
  }
  

  @override
  Widget build(BuildContext context) {
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
      body: isLoading && _selectedIndex != 2 // Only show main loading for non-submission tabs
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_selectedIndex == 0) ...[
                  _buildHeader(),
                  _buildFilters(),
                ],
                Expanded(
                  child: _buildPage(),
                ),
              ],
            ),
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
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

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
    // Handle loading state specifically for sections needing mock data
    if (isLoading && _selectedIndex != 2) {
       return const Center(child: CircularProgressIndicator());
    }
    
    // For Visitors and Events, check city and stats
    if (_selectedIndex != 2) {
      if (selectedCity == null) {
        return const Center(child: Text('Please select a city'));
      }
      final stats = cityStats[selectedCity!];
      if (stats == null) return const Center(child: Text('No data available for this city'));

      switch (_selectedIndex) {
        case 0:
          return VisitorStatsSection(stats: stats);
        case 1:
          return EventManagementSection(stats: stats);
      }
    } 
    // For Submissions, pass the service
    else if (_selectedIndex == 2) {
       // Pass the submissionService from the widget
       return SubmissionSection(submissionService: widget.submissionService);
    }

    // Default fallback
    return const Center(child: Text('Page not found'));
  }

  Widget _buildHeader() {
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
                    setState(() {
                      selectedCity = newValue;
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
                setState(() {
                  selectedTimeFrame = value!;
                });
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
                setState(() {
                  selectedVisitorType = value!;
                });
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