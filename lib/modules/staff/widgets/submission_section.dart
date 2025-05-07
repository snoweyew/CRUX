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
  List<LocalSubmission> _approvedSubmissions = []; // Added to track approved submissions
  bool _isLoading = true;
  String? _error;
  bool _showApproved = false; // Toggle between pending and approved views

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

  Future<void> _fetchApprovedSubmissions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final submissions = await widget.submissionService.getSubmissionsByStatus(SubmissionStatus.approved);
      if (mounted) {
        setState(() {
          _approvedSubmissions = submissions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error fetching approved submissions: $e';
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
      if (status == SubmissionStatus.approved) {
        // Also refresh approved list if we're showing approved submissions
        if (_showApproved) {
          _fetchApprovedSubmissions();
        }
      }
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

  // Function to handle deletion of approved submissions
  Future<void> _deleteSubmission(LocalSubmission submission) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Submission'),
          content: const Text('Are you sure you want to delete this submission? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ElevatedButton(
              child: const Text('Delete'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
    
    if (confirmed == true) {
      try {
        await widget.submissionService.deleteSubmission(submission.id);
        
        // Refresh approved submissions list
        if (_showApproved) {
          _fetchApprovedSubmissions();
        }
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
               content: Text('Submission deleted successfully'),
               backgroundColor: Colors.green,
             ),
           );
        }
      } catch (e) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('Error deleting submission: $e'),
               backgroundColor: Colors.red,
             ),
           );
         }
      }
    }
  }

  // Function to show edit dialog for approved submissions
  Future<void> _showEditDialog(LocalSubmission submission) async {
    final nameController = TextEditingController(text: submission.name);
    final locationController = TextEditingController(text: submission.location);
    final categoryController = TextEditingController(text: submission.category);
    final descriptionController = TextEditingController(text: submission.description);
    
    // Start and end times
    TimeOfDay startTime = submission.startTime;
    TimeOfDay endTime = submission.endTime;
    
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Edit Submission'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (value) => value!.isEmpty ? 'Name is required' : null,
                      ),
                      TextFormField(
                        controller: locationController,
                        decoration: const InputDecoration(labelText: 'Location'),
                        validator: (value) => value!.isEmpty ? 'Location is required' : null,
                      ),
                      TextFormField(
                        controller: categoryController,
                        decoration: const InputDecoration(labelText: 'Category'),
                        validator: (value) => value!.isEmpty ? 'Category is required' : null,
                      ),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(labelText: 'Description'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('Start Time: '),
                          TextButton(
                            onPressed: () async {
                              final newTime = await showTimePicker(
                                context: context,
                                initialTime: startTime,
                              );
                              if (newTime != null) {
                                setStateDialog(() {
                                  startTime = newTime;
                                });
                              }
                            },
                            child: Text('${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}'),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text('End Time: '),
                          TextButton(
                            onPressed: () async {
                              final newTime = await showTimePicker(
                                context: context,
                                initialTime: endTime,
                              );
                              if (newTime != null) {
                                setStateDialog(() {
                                  endTime = newTime;
                                });
                              }
                            },
                            child: Text('${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}'),
                          ),
                        ],
                      ),
                    ],
                  ),
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
                  child: const Text('Save Changes'),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      try {
                        await widget.submissionService.updateSubmission(
                          submissionId: submission.id,
                          name: nameController.text,
                          location: locationController.text,
                          category: categoryController.text,
                          description: descriptionController.text,
                          photoUrl: submission.photoUrl ?? '',
                          latitude: submission.latitude,
                          longitude: submission.longitude,
                          startTime: startTime,
                          endTime: endTime,
                        );
                        
                        // Refresh the approved submissions list
                        if (_showApproved) {
                          _fetchApprovedSubmissions();
                        }
                        
                        if (mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Submission updated successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error updating submission: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
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
          // Toggle buttons for switching between pending and approved
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (_showApproved) {
                        setState(() {
                          _showApproved = false;
                          _fetchPendingSubmissions();
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_showApproved ? const Color(0xFF2C2C2C) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Pending',
                        style: TextStyle(
                          color: !_showApproved ? Colors.white : Colors.grey[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (!_showApproved) {
                        setState(() {
                          _showApproved = true;
                          _fetchApprovedSubmissions();
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _showApproved ? const Color(0xFF2C2C2C) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Approved',
                        style: TextStyle(
                          color: _showApproved ? Colors.white : Colors.grey[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Display either pending or approved submissions
          _showApproved ? _buildApprovedSubmissions() : _buildPendingSubmissions(),
        ],
      ),
    );
  }

  Widget _buildPendingSubmissions() {
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
            child: _buildPendingSubmissionItem(submission), 
          );
        },
      );
    }

    return CardWidget(
      title: 'Pending Local Submissions',
      child: Column(
        children: [
          content,
        ],
      ),
    );
  }

  Widget _buildApprovedSubmissions() {
    Widget content;
    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      content = Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    } else if (_approvedSubmissions.isEmpty) {
      content = const Center(child: Text('No approved submissions.'));
    } else {
      content = ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _approvedSubmissions.length,
        itemBuilder: (context, index) {
          final submission = _approvedSubmissions[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildApprovedSubmissionItem(submission), 
          );
        },
      );
    }

    return CardWidget(
      title: 'Approved Local Submissions',
      child: Column(
        children: [
          content,
        ],
      ),
    );
  }

  // For pending submissions
  Widget _buildPendingSubmissionItem(LocalSubmission submission) {
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
                       submission.name,
                       overflow: TextOverflow.ellipsis,
                       style: const TextStyle(
                         fontWeight: FontWeight.bold,
                         color: Color(0xFF2C2C2C),
                       ),
                     ),
                     const SizedBox(height: 4),
                     Text(
                       submission.location,
                       overflow: TextOverflow.ellipsis,
                       style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                     ),
                   ]
                ),
              ),
              const SizedBox(width: 8),
              // Status Chip
              Chip(
                 label: Text(
                   submission.status.name,
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
          // Submitter Info
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'User ID: ${submission.userId.substring(0, 8)}...',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                submission.submittedAt.toString().split(' ')[0],
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
          // Action Buttons for pending submissions
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

  // For approved submissions with edit and delete options
  Widget _buildApprovedSubmissionItem(LocalSubmission submission) {
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
                       submission.name,
                       overflow: TextOverflow.ellipsis,
                       style: const TextStyle(
                         fontWeight: FontWeight.bold,
                         color: Color(0xFF2C2C2C),
                       ),
                     ),
                     const SizedBox(height: 4),
                     Text(
                       submission.location,
                       overflow: TextOverflow.ellipsis,
                       style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                     ),
                   ]
                ),
              ),
              const SizedBox(width: 8),
              // Status Chip
              Chip(
                 label: Text(
                   submission.status.name,
                   style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                 ),
                 backgroundColor: Colors.green, // Color for approved
                 padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                 materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                 labelPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                 visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Submitter Info
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'User ID: ${submission.userId.substring(0, 8)}...',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                submission.submittedAt.toString().split(' ')[0],
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
          // Action Buttons for approved submissions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Delete button
              IconButton(
                onPressed: () => _deleteSubmission(submission),
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Delete submission',
              ),
              // Edit button
              IconButton(
                onPressed: () => _showEditDialog(submission),
                icon: const Icon(Icons.edit, color: Colors.blue),
                tooltip: 'Edit submission',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
