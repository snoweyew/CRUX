import 'package:flutter/material.dart';
import 'dart:io'; // Import dart:io for File
import 'package:image_picker/image_picker.dart'; // Import image_picker
import '../../shared/models/user_model.dart';
import '../../shared/models/local_submission_model.dart';
import '../../shared/services/supabase_submission_service.dart';
import 'submission_history_page.dart';

class LocalSubmissionPage extends StatefulWidget {
  final UserModel user;
  final SupabaseSubmissionService submissionService;

  const LocalSubmissionPage({
    Key? key,
    required this.user,
    required this.submissionService,
  }) : super(key: key);

  @override
  State<LocalSubmissionPage> createState() => _LocalSubmissionPageState();
}

class _LocalSubmissionPageState extends State<LocalSubmissionPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'food';
  XFile? _imageFile; // Store the picked image file
  bool _isSubmitting = false;
  bool _isGettingLocation = false;
  bool _isCapturingPhoto = false;
  
  // Working hours
  int _startHour = 9;
  bool _startIsAM = true;
  int _endHour = 5;
  bool _endIsAM = false;

  // Location data
  double? _latitude;
  double? _longitude;

  final List<String> _categories = ['food', 'experience', 'attraction'];
  final List<int> _hours = List.generate(12, (index) => index + 1);

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateStartTime(int? hour, bool? isAM) {
    if (hour != null) {
      setState(() {
        _startHour = hour;
      });
    }
    if (isAM != null) {
      setState(() {
        _startIsAM = isAM;
      });
    }
    _validateTimeRange();
  }

  void _updateEndTime(int? hour, bool? isAM) {
    if (hour != null) {
      setState(() {
        _endHour = hour;
      });
    }
    if (isAM != null) {
      setState(() {
        _endIsAM = isAM;
      });
    }
    _validateTimeRange();
  }

  void _validateTimeRange() {
    // Convert to 24-hour format for comparison
    int start24Hour = _startHour + (_startIsAM ? 0 : 12);
    if (_startHour == 12) start24Hour = _startIsAM ? 0 : 12;
    
    int end24Hour = _endHour + (_endIsAM ? 0 : 12);
    if (_endHour == 12) end24Hour = _endIsAM ? 0 : 12;

    if (end24Hour <= start24Hour) {
      // If end time is before or equal to start time, adjust end time
      setState(() {
        if (_startIsAM) {
          _endIsAM = false; // Set to PM
          _endHour = _startHour; // Same hour but PM
        } else {
          _endIsAM = false; // Keep at PM
          _endHour = (_startHour % 12) + 1; // Next hour
        }
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    if (_isGettingLocation) return;

    setState(() {
      _isGettingLocation = true;
    });

    try {
      // Simulate getting location with a delay
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        setState(() {
          // Update with mock location data
          _latitude = 1.5533; // Slightly change location for testing
          _longitude = 110.3592;
          _locationController.text = 'Jalan Padungan, Kuching, Sarawak'; // Mock address
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  Future<void> _capturePhoto() async {
    if (_isCapturingPhoto) return;

    setState(() {
      _isCapturingPhoto = true;
    });

    final ImagePicker picker = ImagePicker();
    try {
      // Ask user to choose between camera and gallery
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Image Source'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.camera),
              child: const Text('Camera'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
              child: const Text('Gallery'),
            ),
          ],
        ),
      );

      if (source == null) {
         if (mounted) {
           setState(() { _isCapturingPhoto = false; });
         }
         return; // User cancelled
      }

      // Pick an image
      final XFile? image = await picker.pickImage(source: source);

      if (image != null && mounted) {
        setState(() {
          _imageFile = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturingPhoto = false;
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture or select a photo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_latitude == null || _longitude == null) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(
           content: Text('Please get the current location'),
           backgroundColor: Colors.red,
         ),
       );
       return;
     }

    setState(() {
      _isSubmitting = true;
    });

    String? uploadedPhotoUrl;
    try {
      // 1. Upload the photo first
      uploadedPhotoUrl = await widget.submissionService.uploadPhoto(_imageFile!.path);

      // 2. Create the submission with the uploaded URL
      final startTime = TimeOfDay(hour: _startHour + (_startIsAM ? 0 : 12), minute: 0);
      final endTime = TimeOfDay(hour: _endHour + (_endIsAM ? 0 : 12), minute: 0);

      await widget.submissionService.createSubmission(
        user: widget.user,
        name: _nameController.text,
        location: _locationController.text,
        category: _selectedCategory,
        description: _descriptionController.text,
        photoUrl: uploadedPhotoUrl, // Use the uploaded URL
        latitude: _latitude!,
        longitude: _longitude!,
        startTime: startTime,
        endTime: endTime,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Submission created successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to submission history
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SubmissionHistoryPage(
              user: widget.user,
              submissionService: widget.submissionService,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(uploadedPhotoUrl == null
                ? 'Error uploading photo: $e'
                : 'Error creating submission: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2C2C),
        elevation: 0,
        title: const Text(
          'Submit Location',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Capture
              Center(
                child: GestureDetector(
                  onTap: _isCapturingPhoto ? null : _capturePhoto,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: _isCapturingPhoto
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF2C2C2C),
                              strokeWidth: 2,
                            ),
                          )
                        : _imageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(_imageFile!.path), // Display picked image
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Error displaying image', // Updated error message
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_a_photo, size: 48, color: Colors.grey),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add Photo',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Name Input
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Location Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Mock Map View
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      // Mock Map (grey placeholder)
                      Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.map, size: 48, color: Colors.grey),
                              const SizedBox(height: 8),
                              Text(
                                'Map Preview\nLat: $_latitude\nLng: $_longitude',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Location Controls
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: FloatingActionButton.small(
                          onPressed: _isGettingLocation ? null : _getCurrentLocation,
                          backgroundColor: const Color(0xFF2C2C2C),
                          child: _isGettingLocation
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.my_location),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Location Input
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location Address',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.toUpperCase()),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Description Input
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Working Hours
              const Text(
                'Working Hours',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Start Time
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Start Time',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Hour dropdown
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: DropdownButton<int>(
                                    value: _startHour,
                                    isExpanded: true,
                                    underline: const SizedBox(),
                                    items: _hours.map((hour) {
                                      return DropdownMenuItem(
                                        value: hour,
                                        child: Text(hour.toString()),
                                      );
                                    }).toList(),
                                    onChanged: (value) => _updateStartTime(value, null),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // AM/PM dropdown
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: DropdownButton<bool>(
                                    value: _startIsAM,
                                    isExpanded: true,
                                    underline: const SizedBox(),
                                    items: const [
                                      DropdownMenuItem(
                                        value: true,
                                        child: Text('AM'),
                                      ),
                                      DropdownMenuItem(
                                        value: false,
                                        child: Text('PM'),
                                      ),
                                    ],
                                    onChanged: (value) => _updateStartTime(null, value),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // End Time
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'End Time',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Hour dropdown
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: DropdownButton<int>(
                                    value: _endHour,
                                    isExpanded: true,
                                    underline: const SizedBox(),
                                    items: _hours.map((hour) {
                                      return DropdownMenuItem(
                                        value: hour,
                                        child: Text(hour.toString()),
                                      );
                                    }).toList(),
                                    onChanged: (value) => _updateEndTime(value, null),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // AM/PM dropdown
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: DropdownButton<bool>(
                                    value: _endIsAM,
                                    isExpanded: true,
                                    underline: const SizedBox(),
                                    items: const [
                                      DropdownMenuItem(
                                        value: true,
                                        child: Text('AM'),
                                      ),
                                      DropdownMenuItem(
                                        value: false,
                                        child: Text('PM'),
                                      ),
                                    ],
                                    onChanged: (value) => _updateEndTime(null, value),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C2C2C),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Submit',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}