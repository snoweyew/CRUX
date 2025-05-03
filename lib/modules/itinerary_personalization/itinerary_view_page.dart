import 'package:flutter/material.dart';
import '../../shared/models/user_model.dart';
import 'itinerary_model.dart';

class ItineraryViewPage extends StatefulWidget {
  final UserModel user;
  final ItineraryModel itinerary;

  const ItineraryViewPage({
    Key? key,
    required this.user,
    required this.itinerary,
  }) : super(key: key);

  @override
  State<ItineraryViewPage> createState() => _ItineraryViewPageState();
}

class _ItineraryViewPageState extends State<ItineraryViewPage> {
  int _selectedDay = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2C2C),
        title: Text(
          '${widget.itinerary.location} Itinerary',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildDayTabs(),
          Expanded(
            child: _buildDayContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildDayTabs() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.itinerary.days.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDay = index;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: _selectedDay == index ? const Color(0xFF2C2C2C) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  'Day ${widget.itinerary.days[index].dayNumber}',
                  style: TextStyle(
                    color: _selectedDay == index ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayContent() {
    if (_selectedDay >= widget.itinerary.days.length) {
      return const Center(
        child: Text('No itinerary data available'),
      );
    }

    final day = widget.itinerary.days[_selectedDay];
    
    // Create a sorted list of time slots
    final timeSlots = day.schedule.keys.toList()
      ..sort((a, b) {
        final order = {'MORNING': 0, 'NOON': 1, 'AFTERNOON': 2, 'EVENING': 3};
        return (order[a] ?? 4).compareTo(order[b] ?? 4);
      });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: timeSlots.length,
      itemBuilder: (context, index) {
        final timeSlot = timeSlots[index];
        final activities = day.schedule[timeSlot] ?? [];
        
        if (activities.isEmpty) {
          return Container();
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatTimeSlot(timeSlot),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            ...activities.map((activity) => _buildActivityCard(activity)).toList(),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildActivityCard(Activity activity) {
    Color accentColor;
    IconData icon;
    
    // Set icon and color based on activity type
    switch (activity.type.toLowerCase()) {
      case 'food':
        accentColor = Colors.orange;
        icon = Icons.restaurant;
        break;
      case 'attraction':
        accentColor = Colors.blue;
        icon = Icons.photo_camera;
        break;
      case 'experience':
        accentColor = Colors.purple;
        icon = Icons.event;
        break;
      default:
        accentColor = Colors.teal;
        icon = Icons.place;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activity.address,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (activity.description != null && activity.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                activity.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  String _formatTimeSlot(String timeSlot) {
    switch (timeSlot) {
      case 'MORNING':
        return '🌅 Morning (6am - 12pm)';
      case 'NOON':
        return '☀️ Noon (12pm - 2pm)';
      case 'AFTERNOON':
        return '🏙️ Afternoon (2pm - 6pm)';
      case 'EVENING':
        return '🌆 Evening (6pm - 10pm)';
      default:
        return timeSlot;
    }
  }
}