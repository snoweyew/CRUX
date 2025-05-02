import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // Remove Firestore import
import 'package:supabase_flutter/supabase_flutter.dart'; // Add Supabase import

class VisitorStatsSection extends StatefulWidget {
  const VisitorStatsSection({Key? key}) : super(key: key);

  @override
  State<VisitorStatsSection> createState() => _VisitorStatsSectionState();
}

class _VisitorStatsSectionState extends State<VisitorStatsSection> {
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Remove Firestore instance
  final _supabase = Supabase.instance.client; // Add Supabase client instance

  // Stream for Supabase real-time data
  late final Stream<List<Map<String, dynamic>>> _statsStream;

  @override
  void initState() {
    super.initState();
    // Define the stream to listen to changes in the 'visitor_stats' table
    // Assumes 'city' is the primary key column for Supabase real-time
    _statsStream = _supabase
        .from('visitor_stats')
        .stream(primaryKey: ['city']) // Specify the primary key column(s)
        .order('city', ascending: true); // Order by city name
  }

  @override
  Widget build(BuildContext context) {
    // Use StreamBuilder with the Supabase stream
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _statsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // Handle Supabase specific errors if needed
          final error = snapshot.error;
          String errorMessage = 'Error loading stats';
          if (error is PostgrestException) {
             errorMessage = 'Database Error: ${error.message} (Code: ${error.code})';
          } else {
             errorMessage = 'Error: ${error.toString()}';
          }
           return Center(child: Text(errorMessage));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No visitor statistics found.'));
        }

        // Data is a List<Map<String, dynamic>> from Supabase
        final statsData = snapshot.data!;

        // Process the list of maps into a list of widgets
        final statsWidgets = statsData.map((data) {
          // Extract city (assuming it's a column named 'city')
          final city = data['city'] as String? ?? 'Unknown City';

          // Extract stats, providing defaults if fields are missing or null
          final totalVisitors = data['total_visitors'] as int? ?? 0;
          final malaysianVisitors = data['malaysian_visitors'] as int? ?? 0;
          final foreignVisitors = data['foreign_visitors'] as int? ?? 0;

          // Safely access JSONB maps (state_counts, country_counts)
          // Supabase client usually decodes JSONB columns into Maps
          final stateCounts = (data['state_counts'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, value as int? ?? 0)) ?? {};
          final countryCounts = (data['country_counts'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, value as int? ?? 0)) ?? {};

          // Sort states and countries by count descending for display
          var sortedStates = stateCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          var sortedCountries = countryCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));


          // Build a widget to display stats for this city
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    city,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('Total Visitors: $totalVisitors', style: Theme.of(context).textTheme.titleMedium),
                  Text('Malaysian: $malaysianVisitors', style: Theme.of(context).textTheme.bodyMedium),
                  Text('Foreign: $foreignVisitors', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  if (sortedStates.isNotEmpty) ...[
                     Text('Top Malaysian States:', style: Theme.of(context).textTheme.titleSmall),
                     ...sortedStates.take(5).map((entry) => Text('- ${entry.key}: ${entry.value}')), // Show top 5
                     if (sortedStates.length > 5) const Text('...'),
                     const SizedBox(height: 8),
                  ],
                   if (sortedCountries.isNotEmpty) ...[
                     Text('Top Foreign Countries:', style: Theme.of(context).textTheme.titleSmall),
                     ...sortedCountries.take(5).map((entry) => Text('- ${entry.key}: ${entry.value}')), // Show top 5
                      if (sortedCountries.length > 5) const Text('...'),
                  ],
                  // Optionally display last updated time if needed
                  // if (data['last_updated'] != null) ...[
                  //   const SizedBox(height: 8),
                  //   Text(
                  //     'Last Updated: ${DateFormat.yMd().add_jm().format(DateTime.parse(data['last_updated']))}', // Requires intl package
                  //     style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  //   ),
                  // ]
                ],
              ),
            ),
          );
        }).toList();

        // Display the list of city stats cards
        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: statsWidgets,
        );
      },
    );
  }
}
