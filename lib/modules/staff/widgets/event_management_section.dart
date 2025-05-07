import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../stb_dashboard_page.dart'; 
import 'shared/card_widget.dart'; 
import '../../../shared/utils/date_formatter.dart';

class EventManagementSection extends StatefulWidget {
  final TouristStats stats;

  const EventManagementSection({Key? key, required this.stats}) : super(key: key);

  @override
  State<EventManagementSection> createState() => _EventManagementSectionState();
}

class _EventManagementSectionState extends State<EventManagementSection> {
  final _supabase = Supabase.instance.client;
  List<Event> _events = [];
  bool _isLoading = false;
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  bool _isUploading = false;
  final String _eventsBucket = 'events';

  @override
  void initState() {
    super.initState();
    _initializeEventsBucket();
    _loadEvents();
  }

  // Initialize events storage bucket if it doesn't exist
  Future<void> _initializeEventsBucket() async {
    try {
      // Check if the bucket exists by attempting to get its details
      await _supabase.storage.getBucket(_eventsBucket);
      print('Events bucket already exists');
    } catch (e) {
      if (e.toString().contains('not found')) {
        try {
          // Create the bucket if it doesn't exist
          await _supabase.storage.createBucket(
            _eventsBucket,
            const BucketOptions(
              public: true, // Make images publicly accessible
              fileSizeLimit: '10MB', // The correct parameter name is fileSizeLimit, not fileSize
              allowedMimeTypes: ['image/png', 'image/jpeg', 'image/jpg', 'image/gif'],
            ),
          );
          print('Events bucket created successfully');
        } catch (createError) {
          // Check if it's a 409 Conflict error (bucket already exists)
          if (createError.toString().contains('409') || 
              createError.toString().contains('already exists') ||
              createError.toString().contains('duplicate')) {
            print('Events bucket already exists (created by another process)');
            // No need to show an error to the user as the bucket exists
          } else {
            print('Error creating events bucket: $createError');
            // Show error in UI when context is available
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error creating storage for events: $createError'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            });
          }
        }
      } else {
        print('Error checking events bucket: $e');
        // Show error in UI when context is available
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error accessing event storage: $e'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        });
      }
    }
  }

  // Fetch events from Supabase
  Future<void> _loadEvents() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final response = await _supabase
          .from('events')
          .select()
          .eq('city', widget.stats.city)
          .order('start_date', ascending: true);

      List<Event> events = [];
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      
      // Remove time portion for date comparison
      final todayDate = DateTime(now.year, now.month, now.day);
      final tomorrowDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
      
      for (var item in response) {
        final startDate = DateTime.parse(item['start_date']);
        final endDate = DateTime.parse(item['end_date']);
        
        // Remove time portion for more accurate date comparison
        final eventStartDate = DateTime(startDate.year, startDate.month, startDate.day);
        final eventEndDate = DateTime(endDate.year, endDate.month, endDate.day);
        
        String status;
        
        // If the event start date is today or tomorrow, mark as Ongoing
        if (eventStartDate.isAtSameMomentAs(todayDate) || 
            eventStartDate.isAtSameMomentAs(tomorrowDate) || 
            (eventStartDate.isAfter(todayDate) && eventStartDate.isBefore(tomorrowDate))) {
          status = 'Ongoing';
        }
        // If the event has already started but not ended, mark as Ongoing
        else if (now.isAfter(startDate) && now.isBefore(endDate)) {
          status = 'Ongoing';
        }
        // If the event is in the future (after tomorrow), mark as Upcoming
        else if (eventStartDate.isAfter(tomorrowDate)) {
          status = 'Upcoming';
        }
        // If the event has ended, mark as Expired
        else if (now.isAfter(endDate)) {
          status = 'Expired';
        }
        // Default fallback (should rarely be needed)
        else {
          status = 'Ongoing';
        }
        
        events.add(Event(
          id: item['id'],
          title: item['title'],
          description: item['description'],
          startDate: startDate,
          endDate: endDate,
          venue: item['venue'],
          category: item['category'],
          status: status,
          imageUrl: item['image_url'],
          city: item['city'],
        ));
      }

      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading events: $e')),
        );
      }
    }
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  // Upload image to Supabase Storage
  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;
    
    setState(() {
      _isUploading = true;
    });
    
    try {
      // Generate a unique file name
      final String fileExtension = _selectedImage!.path.split('.').last.toLowerCase();
      final String fileName = '${const Uuid().v4()}.$fileExtension';
      
      // Read file as bytes for more reliable upload
      final bytes = await _selectedImage!.readAsBytes();
      
      // Upload file to Supabase Storage
      await _supabase.storage
          .from(_eventsBucket)
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/$fileExtension',
            ),
          );
          
      // Get the public URL of the uploaded image
      final String imageUrl = _supabase.storage
          .from(_eventsBucket)
          .getPublicUrl(fileName);
          
      setState(() {
        _isUploading = false;
        _selectedImage = null;
      });
      
      print('Image uploaded successfully: $imageUrl');
      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      return null;
    }
  }

  // Add new event to Supabase
  Future<void> _addEvent(Event event) async {
    try {
      await _supabase.from('events').insert({
        'title': event.title,
        'description': event.description,
        'start_date': event.startDate.toIso8601String(),
        'end_date': event.endDate.toIso8601String(),
        'venue': event.venue,
        'category': event.category,
        'status': event.status,
        'image_url': event.imageUrl,
        'city': widget.stats.city,
      });

      // Refresh events list
      await _loadEvents();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add event: $e')),
      );
    }
  }

  // Update event status to expired
  Future<void> _updateEventStatus(String id, String status) async {
    try {
      await _supabase
          .from('events')
          .update({'status': status})
          .eq('id', id);

      // Refresh events list
      await _loadEvents();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Event marked as $status')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update event: $e')),
      );
    }
  }

  // Delete event
  Future<void> _deleteEvent(String id) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Event'),
          content: const Text('Are you sure you want to delete this event? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
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
        await _supabase.from('events').delete().eq('id', id);
        
        // Refresh events list
        await _loadEvents();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete event: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Edit event
  Future<void> _updateEvent(Event event) async {
    try {
      await _supabase.from('events').update({
        'title': event.title,
        'description': event.description,
        'start_date': event.startDate.toIso8601String(),
        'end_date': event.endDate.toIso8601String(),
        'venue': event.venue,
        'category': event.category,
        'status': event.status,
        'image_url': event.imageUrl,
      }).eq('id', event.id);

      // Refresh events list
      await _loadEvents();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update event: $e')),
      );
    }
  }

  // Show edit event dialog
  void _showEditEventDialog(Event event) {
    final titleController = TextEditingController(text: event.title);
    final descriptionController = TextEditingController(text: event.description);
    final venueController = TextEditingController(text: event.venue);
    final categoryController = TextEditingController(text: event.category);
    
    DateTime startDate = event.startDate;
    DateTime endDate = event.endDate;
    
    // Reset selected image
    setState(() {
      _selectedImage = null;
    });

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Edit Event'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    TextField(
                      controller: venueController,
                      decoration: const InputDecoration(labelText: 'Venue'),
                    ),
                    TextField(
                      controller: categoryController,
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    const SizedBox(height: 16),
                    const Text('Event Image:'),
                    const SizedBox(height: 8),
                    
                    // Image preview or placeholder
                    GestureDetector(
                      onTap: () async {
                        await _pickImage();
                        setStateDialog(() {}); // Update dialog state to show selected image
                      },
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : event.imageUrl != null && event.imageUrl!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      event.imageUrl!,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, progress) => 
                                        progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                      errorBuilder: (context, error, stack) => 
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: const [
                                            Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                            SizedBox(height: 8),
                                            Text('Image not available'),
                                          ],
                                        ),
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text('Tap to select image'),
                                    ],
                                  ),
                      ),
                    ),
                    
                    if (_isUploading) 
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: LinearProgressIndicator(),
                      ),
                    
                    const SizedBox(height: 16),
                    const Text('Start Date:'),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setStateDialog(() {
                            startDate = picked;
                            // Ensure end date is not before start date
                            if (endDate.isBefore(startDate)) {
                              endDate = startDate;
                            }
                          });
                        }
                      },
                      child: Text(startDate.toString().split(' ')[0]),
                    ),
                    const Text('End Date:'),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: endDate.isAfter(startDate) ? endDate : startDate,
                          firstDate: startDate,
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setStateDialog(() {
                            endDate = picked;
                          });
                        }
                      },
                      child: Text(endDate.toString().split(' ')[0]),
                    ),
                    const SizedBox(height: 16),
                    const Text('Status:'),
                    DropdownButtonFormField<String>(
                      value: event.status,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(value: 'Upcoming', child: Text('Upcoming')),
                        DropdownMenuItem(value: 'Ongoing', child: Text('Ongoing')),
                        DropdownMenuItem(value: 'Expired', child: Text('Expired')),
                      ],
                      onChanged: (value) {
                        setStateDialog(() {
                          event = Event(
                            id: event.id,
                            title: event.title,
                            description: event.description,
                            startDate: event.startDate,
                            endDate: event.endDate,
                            venue: event.venue,
                            category: event.category,
                            status: value!,
                            imageUrl: event.imageUrl,
                            city: event.city,
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isUploading ? null : () async {
                    if (titleController.text.isEmpty || 
                        descriptionController.text.isEmpty ||
                        venueController.text.isEmpty ||
                        categoryController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all required fields')),
                      );
                      return;
                    }

                    // Upload image if selected
                    String? imageUrl = event.imageUrl;
                    if (_selectedImage != null) {
                      setStateDialog(() {
                        _isUploading = true;
                      });
                      
                      imageUrl = await _uploadImage();
                      
                      setStateDialog(() {
                        _isUploading = false;
                      });
                      
                      if (imageUrl == null) {
                        // Image upload failed
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Image upload failed')),
                        );
                        return;
                      }
                    }

                    final updatedEvent = Event(
                      id: event.id,
                      title: titleController.text,
                      description: descriptionController.text,
                      startDate: startDate,
                      endDate: endDate,
                      venue: venueController.text,
                      category: categoryController.text,
                      status: event.status,
                      imageUrl: imageUrl,
                      city: event.city,
                    );

                    await _updateEvent(updatedEvent);
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C2C2C),
                    foregroundColor: Colors.white,
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddEventDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final venueController = TextEditingController();
    final categoryController = TextEditingController();
    
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 1));
    
    // Reset selected image
    setState(() {
      _selectedImage = null;
    });

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Add New Event'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    TextField(
                      controller: venueController,
                      decoration: const InputDecoration(labelText: 'Venue'),
                    ),
                    TextField(
                      controller: categoryController,
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    const SizedBox(height: 16),
                    const Text('Event Image:'),
                    const SizedBox(height: 8),
                    
                    // Image preview or placeholder
                    GestureDetector(
                      onTap: () async {
                        await _pickImage();
                        setStateDialog(() {}); // Update dialog state to show selected image
                      },
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Tap to select image'),
                                ],
                              ),
                      ),
                    ),
                    
                    if (_isUploading) 
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: LinearProgressIndicator(),
                      ),
                    
                    const SizedBox(height: 16),
                    const Text('Start Date:'),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setStateDialog(() {
                            startDate = picked;
                            // Ensure end date is not before start date
                            if (endDate.isBefore(startDate)) {
                              endDate = startDate;
                            }
                          });
                        }
                      },
                      child: Text(startDate.toString().split(' ')[0]),
                    ),
                    const Text('End Date:'),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: endDate.isAfter(startDate) ? endDate : startDate,
                          firstDate: startDate,
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setStateDialog(() {
                            endDate = picked;
                          });
                        }
                      },
                      child: Text(endDate.toString().split(' ')[0]),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isUploading ? null : () async {
                    if (titleController.text.isEmpty || 
                        descriptionController.text.isEmpty ||
                        venueController.text.isEmpty ||
                        categoryController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all required fields')),
                      );
                      return;
                    }

                    // Upload image if selected
                    String? imageUrl;
                    if (_selectedImage != null) {
                      setStateDialog(() {
                        _isUploading = true;
                      });
                      
                      imageUrl = await _uploadImage();
                      
                      setStateDialog(() {
                        _isUploading = false;
                      });
                      
                      if (imageUrl == null) {
                        // Image upload failed
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Image upload failed')),
                        );
                        return;
                      }
                    }

                    final newEvent = Event(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text,
                      description: descriptionController.text,
                      startDate: startDate,
                      endDate: endDate,
                      venue: venueController.text,
                      category: categoryController.text,
                      status: 'Upcoming',
                      imageUrl: imageUrl,
                      city: widget.stats.city,
                    );

                    await _addEvent(newEvent);
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C2C2C),
                    foregroundColor: Colors.white,
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Show event details and options
  void _showEventDetails(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      event.imageUrl!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(
                        height: 150,
                        child: Center(child: Icon(Icons.broken_image)),
                      ),
                    ),
                  ),
                ),
              Text('Description: ${event.description}'),
              const SizedBox(height: 8),
              Text('Venue: ${event.venue}'),
              const SizedBox(height: 8),
              Text('Category: ${event.category}'),
              const SizedBox(height: 8),
              Text('Date: ${DateFormatter.formatRange(event.startDate, event.endDate)}'),
              const SizedBox(height: 8),
              Text('Status: ${event.status}', 
                style: TextStyle(
                  color: event.status == 'Upcoming' ? Colors.green : 
                        event.status == 'Ongoing' ? Colors.blue : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (event.status == 'Upcoming')
            TextButton(
              onPressed: () {
                _updateEventStatus(event.id, 'Expired');
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Mark as Expired'),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditEventDialog(event);
            },
            child: const Text('Edit'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEvent(event.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildEventManagement(),
        ],
      ),
    );
  }

  Widget _buildEventManagement() {
    return CardWidget(
      title: 'Event Management',
      child: Column(
        children: [
          _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No events found for this city'),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _events.length,
                itemBuilder: (context, index) {
                  final event = _events[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildEventItem(
                      event.title,
                      DateFormatter.formatRange(event.startDate, event.endDate),
                      event.venue,
                      event.status,
                      onTap: () => _showEventDetails(event),
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
                    // Navigate to event list in EventView
                    // Implementation would depend on your navigation setup
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('View all events in Events tab')),
                    );
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
                  onPressed: _showAddEventDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C2C2C),
                    foregroundColor: Colors.white,
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

  Widget _buildEventItem(String title, String date, String venue, String status, {required VoidCallback onTap}) {
    // Define colors based on status
    Color statusColor;
    Color statusBackgroundColor;
    
    if (status == 'Upcoming') {
      statusColor = Colors.green;
      statusBackgroundColor = Colors.green.withOpacity(0.1);
    } else if (status == 'Ongoing') {
      statusColor = Colors.blue;
      statusBackgroundColor = Colors.blue.withOpacity(0.1);
    } else {
      statusColor = Colors.grey;
      statusBackgroundColor = Colors.grey.withOpacity(0.1);
    }
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                color: statusColor,
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
                color: statusBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
