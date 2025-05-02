import 'package:flutter/material.dart';
// Remove the import for the old stb_dashboard_page models if present
// import '../stb_dashboard_page.dart'; 
import '../../../shared/models/local_submission_model.dart'; // Use the correct model
import '../../../shared/services/supabase_submission_service.dart'; // Import the service
import 'shared/card_widget.dart';

// Convert to StatefulWidget
class SubmissionSection extends StatefulWidget {
  // Remove TouristStats, add SupabaseSubmissionService
  // final TouristStats stats; 
  final SupabaseSubmissionService submissionService;

  const SubmissionSection({
    Key? key, 
    required this.submissionService, // Require the service
  }) : super(key: key);

  @override
  State<SubmissionSection> createState() => _SubmissionSectionState();
}

class _SubmissionSectionState extends State<SubmissionSection> {
  List<LocalSubmission> _pendingSubmissions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPendingSubmissions();
  }

  Future<void> _fetchPendingSubmissions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final submissions = await widget.submissionService.getSubmissionsByStatus(SubmissionStatus.pending);
      if (mounted) {
        setState(() {
          _pendingSubmissions = submissions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error fetching submissions: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateStatus(LocalSubmission submission, SubmissionStatus status, {String? reason}) async {
    // Optional: Show confirmation dialog
    
    try {
      await widget.submissionService.updateSubmissionStatus(
        submissionId: submission.id,
        status: status,
        rejectionReason: reason,
      );
      // Refresh the list after updating
      _fetchPendingSubmissions(); 
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Submission ${status.name} successfully'),
             backgroundColor: Colors.green,
           ),
         );
      }
    } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Error updating submission: $e'),
             backgroundColor: Colors.red,
           ),
         );
       }
    }
  }
  
  // Function to show rejection reason dialog
  Future<void> _showRejectionDialog(LocalSubmission submission) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reject Submission'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: reasonController,
              decoration: const InputDecoration(hintText: "Reason for rejection (optional)"),
              maxLines: 3,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Reject'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                 // No validation needed for optional field
                 Navigator.of(context).pop(); // Close dialog first
                 _updateStatus(submission, SubmissionStatus.rejected, reason: reasonController.text.trim());
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildLocalSubmissions(), // Pass the service
        ],
      ),
    );
  }

  Widget _buildLocalSubmissions() {
    Widget content;
    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      content = Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    } else if (_pendingSubmissions.isEmpty) {
      content = const Center(child: Text('No pending submissions.'));
    } else {
      content = ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _pendingSubmissions.length,
        itemBuilder: (context, index) {
          final submission = _pendingSubmissions[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            // Pass submission and service to the item builder
            child: _buildSubmissionItem(submission), 
          );
        },
      );
    }

    return CardWidget(
      title: 'Pending Local Submissions',
      child: Column(
        children: [
          content,
          const SizedBox(height: 16),
          // Keep the "View All" button if needed, or remove if this section only shows pending
          ElevatedButton(
            onPressed: () {
              // TODO: Navigate to a page showing ALL submissions (approved, rejected too)
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C2C2C),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 40),
            ),
            child: const Text('View All Submissions History'),
          ),
        ],
      ),
    );
  }

  // Modify to accept LocalSubmission object
  Widget _buildSubmissionItem(LocalSubmission submission) {
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
                child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                       submission.name, // Use name from submission
                       overflow: TextOverflow.ellipsis,
                       style: const TextStyle(
                         fontWeight: FontWeight.bold,
                         color: Color(0xFF2C2C2C),
                       ),
                     ),
                     const SizedBox(height: 4),
                     Text(
                       submission.location, // Show location
                       overflow: TextOverflow.ellipsis,
                       style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                     ),
                   ]
                ),
              ),
              const SizedBox(width: 8),
              // Status Chip (though all should be pending here)
              Chip(
                 label: Text(
                   submission.status.name, // Use status from submission
                   style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                 ),
                 backgroundColor: Colors.orange, // Color for pending
                 padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                 materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                 labelPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                 visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Submitter Info (Consider fetching submitter name if needed)
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'User ID: ${submission.userId.substring(0, 8)}...', // Show partial user ID
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                submission.submittedAt.toString().split(' ')[0], // Format date
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Description
           if (submission.description.isNotEmpty) ...[
             Text(
               submission.description,
               style: const TextStyle(fontSize: 13),
               maxLines: 2,
               overflow: TextOverflow.ellipsis,
             ),
             const SizedBox(height: 8),
           ],
          // Photo Preview (Optional)
          if (submission.photoUrl != null && submission.photoUrl!.isNotEmpty) ...[
             Center(
               child: Image.network(
                 submission.photoUrl!,
                 height: 150,
                 fit: BoxFit.cover,
                 loadingBuilder: (context, child, progress) => 
                   progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                 errorBuilder: (context, error, stack) => 
                   const Icon(Icons.broken_image, color: Colors.grey, size: 40),
               ),
             ),
             const SizedBox(height: 12),
          ],
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _showRejectionDialog(submission),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Reject'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _updateStatus(submission, SubmissionStatus.approved),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Approve'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
