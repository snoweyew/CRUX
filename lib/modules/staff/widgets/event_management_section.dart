import 'package:flutter/material.dart';
import '../stb_dashboard_page.dart'; // Import necessary models/classes
import 'shared/card_widget.dart'; // Import the shared card widget

class EventManagementSection extends StatelessWidget {
  final TouristStats stats;

  const EventManagementSection({Key? key, required this.stats}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildEventManagement(stats),
        ],
      ),
    );
  }

  Widget _buildEventManagement(TouristStats stats) {
    // Using mock data for now as events list is empty in the provided code
    final mockEvents = List.generate(3, (index) => Event(
      title: 'Rainforest Music Festival',
      description: 'Annual music festival',
      startDate: DateTime.now().add(Duration(days: 30 + index * 10)),
      endDate: DateTime.now().add(Duration(days: 32 + index * 10)),
      venue: 'Sarawak Cultural Village',
      category: 'Music',
      status: index == 0 ? 'Upcoming' : 'Past',
    ));

    return CardWidget(
      title: 'Event Management',
      child: Column(
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: mockEvents.length,
            itemBuilder: (context, index) {
              final event = mockEvents[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildEventItem(
                  event.title,
                  '${event.startDate.toString().split(' ')[0]} - ${event.endDate.toString().split(' ')[0]}', // Format date range
                  event.venue,
                  event.status,
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
                    foregroundColor: Colors.white, // Ensure text is visible
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
}
