import 'package:flutter/material.dart';
import '../stb_dashboard_page.dart'; // Import necessary models/classes if needed
import 'shared/card_widget.dart'; // Import the shared card widget

class VisitorStatsSection extends StatelessWidget {
  final TouristStats stats;

  const VisitorStatsSection({Key? key, required this.stats}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  '${stats.malaysianVisitors}', // Use actual malaysianVisitors count
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
                // const SizedBox(height: 8),
                // _buildTrendIndicator(10.5), // TODO: Implement trend calculation if needed
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
                  '${stats.foreignVisitors}', // Use actual foreignVisitors count
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
                // const SizedBox(height: 8),
                // _buildTrendIndicator(-5.2), // TODO: Implement trend calculation if needed
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisitorsByCountry(TouristStats stats) {
     return CardWidget( // Use CardWidget
      title: 'Visitors by Country',
      child: stats.visitorsByCountry.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No country data available.', style: TextStyle(color: Colors.grey)),
            ) 
          : Column(
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
                          // Ensure visitorCount is not zero to avoid division by zero
                          // Use total visitor count for percentage calculation
                          value: stats.visitorCount > 0 ? entry.value / stats.visitorCount : 0,
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

   Widget _buildSatisfactionRatings(TouristStats stats) {
    // Use actual ratings if available, otherwise use mock
    final ratings = stats.satisfactionRatings.isNotEmpty
        ? stats.satisfactionRatings
        : {
            // 'Overall': 4.5, // Keep commented or remove if not used
            // 'Accommodation': 4.2,
            // 'Transportation': 3.8,
            // 'Activities': 4.7,
          };

    // If no ratings, show a message
    if (ratings.isEmpty) {
      return CardWidget(
        title: 'Tourist Satisfaction',
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No satisfaction data available.', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return CardWidget( // Use CardWidget
      title: 'Tourist Satisfaction',
      child: Column(
        children: ratings.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildRatingBar(entry.key, entry.value),
          );
        }).toList()..removeLast(), // Remove padding from the last item
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

  // Remove _buildCard as it's now imported
  // Widget _buildCard({required String title, required Widget child}) { ... }

  // Keep _buildVisitorStats as it uses _buildCard internally for its structure
   Widget _buildCard({required String title, required Widget child}) {
    return CardWidget(title: title, child: child);
  }
}
