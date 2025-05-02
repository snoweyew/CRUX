import 'package:flutter/material.dart';
import '../stb_dashboard_page.dart'; // Import necessary models/classes
import 'shared/card_widget.dart'; // Import the shared card widget

class SubmissionSection extends StatelessWidget {
  final TouristStats stats;

  const SubmissionSection({Key? key, required this.stats}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildLocalSubmissions(stats),
        ],
      ),
    );
  }

  Widget _buildLocalSubmissions(TouristStats stats) {
    // Using mock data for now as pendingSubmissions list is empty in the provided code
    final mockSubmissions = List.generate(3, (index) => LocalSubmission(
      id: 'sub${index + 1}',
      title: 'New Tourist Spot Registration',
      description: 'Details about the new spot...',
      submitterName: 'John Doe',
      date: DateTime.now().subtract(Duration(days: index)),
      status: 'Pending Review',
    ));

    return CardWidget(
      title: 'Local Submissions',
      child: Column(
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: mockSubmissions.length,
            itemBuilder: (context, index) {
              final submission = mockSubmissions[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSubmissionItem(
                  submission.title,
                  submission.submitterName,
                  submission.status,
                  submission.date,
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
              foregroundColor: Colors.white, // Ensure text is visible
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
                  overflow: TextOverflow.ellipsis, // Prevent overflow
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
              ),
              const SizedBox(width: 8), // Add spacing
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
                date.toString().split(' ')[0], // Format date
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
}
