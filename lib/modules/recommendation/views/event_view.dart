import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../shared/services/recommendation_service.dart';
import '../../../shared/utils/date_formatter.dart';
import 'package:card_swiper/card_swiper.dart';
import 'recommendation_list_view_base.dart';

// View for Events with card swipe functionality
class EventView extends StatefulWidget {
  final RecommendationService recommendationService;
  final String selectedCity;
  final Animation<double> fadeAnimation;

  const EventView({
    Key? key,
    required this.recommendationService,
    required this.selectedCity,
    required Animation<double> fadeAnimation,
    required RecommendationCardBuilder cardBuilder,
  }) : fadeAnimation = fadeAnimation, super(key: key);

  @override
  State<EventView> createState() => _EventViewState();
}

class _EventViewState extends State<EventView> {
  @override
  Widget build(BuildContext context) {
    // Calculate safe area to avoid overlapping navigation bar
    final bottomPadding = MediaQuery.of(context).padding.bottom + 70; // Add extra space for bottom nav bar

    return FadeTransition(
      opacity: widget.fadeAnimation,
      child: FutureBuilder<List<Map<String, String>>>(
        future: widget.recommendationService.fetchRecommendations('events', city: widget.selectedCity),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading events: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text('No events found for ${widget.selectedCity}.'),
            );
          }

          // Filter out expired events
          final List<Map<String, String>> events = snapshot.data!.where((event) {
            // Check if event has end date
            if (event.containsKey('endDate') && event['endDate'] != null && event['endDate']!.isNotEmpty) {
              try {
                final DateTime endDate = DateTime.parse(event['endDate']!);
                return !DateFormatter.isPast(endDate); // Keep only non-expired events
              } catch (e) {
                return true; // If date parsing fails, include the event
              }
            }
            return true; // If no end date, include the event
          }).toList();

          if (events.isEmpty) {
            return const Center(
              child: Text('No upcoming events at this time.'),
            );
          }

          // Use Swiper for card swipe effect with adjusted padding
          return Padding(
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, bottomPadding),
            child: Swiper(
              itemBuilder: (context, index) => _buildEventCard(context, events[index]),
              itemCount: events.length,
              viewportFraction: 0.85,
              scale: 0.9,
              autoplay: false,
              pagination: const SwiperPagination(
                alignment: Alignment.bottomCenter,
                builder: DotSwiperPaginationBuilder(
                  activeColor: Color(0xFF2C2C2C),
                  color: Colors.grey,
                ),
                margin: EdgeInsets.only(bottom: 12),
              ),
              control: const SwiperControl(
                color: Color(0xFF2C2C2C),
                disableColor: Colors.grey,
                size: 30,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Map<String, String> event) {
    // Extract event dates for display
    String dateDisplay = "Date not specified";
    bool isExpired = false;

    if (event.containsKey('startDate') && event['startDate'] != null && event['startDate']!.isNotEmpty) {
      try {
        final DateTime startDate = DateTime.parse(event['startDate']!);
        
        if (event.containsKey('endDate') && event['endDate'] != null && event['endDate']!.isNotEmpty) {
          final DateTime endDate = DateTime.parse(event['endDate']!);
          dateDisplay = DateFormatter.formatRange(startDate, endDate);
          isExpired = DateFormatter.isPast(endDate);
        } else {
          dateDisplay = "${startDate.day}/${startDate.month}/${startDate.year}";
          isExpired = DateFormatter.isPast(startDate);
        }
      } catch (e) {
        dateDisplay = "Invalid date format";
      }
    }

    // Determine if event is upcoming, ongoing, or expired
    String status = isExpired ? "Expired" : "Upcoming";
    if (!isExpired && event.containsKey('startDate') && event['startDate'] != null) {
      try {
        final DateTime startDate = DateTime.parse(event['startDate']!);
        if (DateFormatter.isPast(startDate)) {
          status = "Ongoing";
        }
      } catch (e) {
        // Use default status if date parsing fails
      }
    }

    // Define colors based on status
    Color statusColor;
    Color statusBackgroundColor;
    
    switch (status) {
      case 'Expired':
        statusColor = Colors.red;
        statusBackgroundColor = Colors.red.withOpacity(0.1);
        break;
      case 'Ongoing':
        statusColor = Colors.green;
        statusBackgroundColor = Colors.green.withOpacity(0.1);
        break;
      case 'Upcoming':
      default:
        statusColor = Colors.blue;
        statusBackgroundColor = Colors.blue.withOpacity(0.1);
        break;
    }

    // Calculate the height of the card for proper proportions
    final double cardHeight = MediaQuery.of(context).size.height * 0.65;
    final double imageHeight = cardHeight * 0.75; // Image takes 3/4 of the card
    final double contentHeight = cardHeight * 0.25; // Content takes 1/4 of the card

    // Create visually appealing event card with drop shadow and glassmorphism effect
    return Container(
      height: cardHeight,
      margin: const EdgeInsets.only(bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background image taking 3/4 of the height
            Positioned.fill(
              child: event.containsKey('imageUrl') && event['imageUrl'] != null && event['imageUrl']!.isNotEmpty
                ? Image.network(
                    event['imageUrl']!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[300],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / 
                                    (loadingProgress.expectedTotalBytes ?? 1)
                                : null,
                            color: const Color(0xFF2C2C2C),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 60, color: Colors.grey),
                      ),
                    ),
                  )
                : Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.event, size: 60, color: Colors.grey),
                    ),
                  ),
            ),
            
            // Gradient overlay at the top (subtle)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            
            // Status badge with glassmorphism at top right
            Positioned(
              top: 16,
              right: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusBackgroundColor.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Content section with glassmorphism at the bottom (1/4 of card)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: contentHeight,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.0,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event title
                        Text(
                          event['name'] ?? event['title'] ?? 'Unnamed Event',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 4.0,
                                color: Colors.black54,
                                offset: Offset(1.0, 1.0),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        
                        // Date and venue information
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: Colors.white),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                dateDisplay,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 4.0,
                                      color: Colors.black54,
                                      offset: Offset(1.0, 1.0),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Colors.white),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                event['location'] ?? event['venue'] ?? 'Location not specified',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 4.0,
                                      color: Colors.black54,
                                      offset: Offset(1.0, 1.0),
                                    ),
                                  ],
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
              ),
            ),
            
            // Swipe hint with glassmorphism at the bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.swipe, size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          'Swipe for more events',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
