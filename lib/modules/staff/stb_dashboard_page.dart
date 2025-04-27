import 'package:flutter/material.dart';
import '../../shared/models/user_model.dart';
import '../../shared/services/mock_data_service.dart';

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

  const STBDashboardPage({
    Key? key,
    required this.user,
    required this.mockDataService,
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
      setState(() {
        cityStats = mockStats;
        isLoading = false;
      });
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

      stats[city] = TouristStats(
        city: city,
        visitorCount: visitorCount,
        visitorsByCountry: visitorsByCountry,
        orders: orders,
        satisfactionRatings: {},
        complaints: [],
        events: [],
        pendingSubmissions: [],
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
      body: isLoading
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
    if (selectedCity == null) {
      return const Center(child: Text('Please select a city'));
    }

    final stats = cityStats[selectedCity!];
    if (stats == null) return const Center(child: Text('No data available'));

    switch (_selectedIndex) {
      case 0:
        return _buildVisitorsPage(stats);
      case 1:
        return _buildEventsPage(stats);
      case 2:
        return _buildSubmissionsPage(stats);
      default:
        return const Center(child: Text('Page not found'));
    }
  }

  Widget _buildVisitorsPage(TouristStats stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVisitorStats(stats),
          const SizedBox(height: 16),
          _buildVisitorsByCountry(stats),
          const SizedBox(height: 16),
          _buildSatisfactionRatings(stats),
        ],
      ),
    );
  }

  Widget _buildVisitorsByCountry(TouristStats stats) {
    return _buildCard(
      title: 'Visitors by Country',
      child: Column(
        children: [
          ...stats.visitorsByCountry.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2C),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${entry.value}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: entry.value / stats.visitorCount,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF2C2C2C),
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildEventsPage(TouristStats stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildEventManagement(stats),
        ],
      ),
    );
  }

  Widget _buildSubmissionsPage(TouristStats stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildLocalSubmissions(stats),
        ],
      ),
    );
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

  Widget _buildVisitorStats(TouristStats stats) {
    return Row(
      children: [
        Expanded(
          child: _buildCard(
            title: 'Local Visitors',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${stats.visitorCount ~/ 2}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
                const SizedBox(height: 8),
                _buildTrendIndicator(10.5),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildCard(
            title: 'Foreign Visitors',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${stats.visitorCount ~/ 2}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
                const SizedBox(height: 8),
                _buildTrendIndicator(-5.2),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendIndicator(double percentage) {
    final isPositive = percentage >= 0;
    return Row(
      children: [
        Icon(
          isPositive ? Icons.trending_up : Icons.trending_down,
          color: isPositive ? Colors.green : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          '${percentage.abs()}%',
          style: TextStyle(
            color: isPositive ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSatisfactionRatings(TouristStats stats) {
    return _buildCard(
      title: 'Tourist Satisfaction',
      child: Column(
        children: [
          _buildRatingBar('Overall', 4.5),
          const SizedBox(height: 12),
          _buildRatingBar('Accommodation', 4.2),
          const SizedBox(height: 12),
          _buildRatingBar('Transportation', 3.8),
          const SizedBox(height: 12),
          _buildRatingBar('Activities', 4.7),
        ],
      ),
    );
  }

  Widget _buildRatingBar(String label, double rating) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2C2C2C),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: index < rating ? const Color(0xFF2C2C2C) : Colors.grey,
                size: 16,
              );
            }),
          ),
        ),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C2C2C),
          ),
        ),
      ],
    );
  }

  Widget _buildEventManagement(TouristStats stats) {
    return _buildCard(
      title: 'Event Management',
      child: Column(
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildEventItem(
                  'Rainforest Music Festival',
                  'July 12-14, 2024',
                  'Sarawak Cultural Village',
                  index == 0 ? 'Upcoming' : 'Past',
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Navigate to event list
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2C2C2C),
                    side: const BorderSide(color: Color(0xFF2C2C2C)),
                  ),
                  child: const Text('View All'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Navigate to add event page
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C2C2C),
                  ),
                  child: const Text('Add Event'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem(String title, String date, String venue, String status) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: status == 'Upcoming' ? Colors.green : Colors.grey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$date • $venue',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: status == 'Upcoming'
                  ? Colors.green.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                color: status == 'Upcoming' ? Colors.green : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalSubmissions(TouristStats stats) {
    return _buildCard(
      title: 'Local Submissions',
      child: Column(
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSubmissionItem(
                  'New Tourist Spot Registration',
                  'John Doe',
                  'Pending Review',
                  DateTime.now().subtract(Duration(days: index)),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // TODO: Navigate to submissions page
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C2C2C),
              minimumSize: const Size(double.infinity, 40),
            ),
            child: const Text('View All Submissions'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionItem(
    String title,
    String submitter,
    String status,
    DateTime date,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2C2C2C),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.person,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                submitter,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.calendar_today,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                date.toString().split(' ')[0],
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFEEEEEE),
                  width: 1,
                ),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C2C),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
} 