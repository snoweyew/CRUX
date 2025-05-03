import 'package:flutter/material.dart';
import '../../shared/models/user_model.dart';
import '../../shared/services/itinerary_storage_service.dart';
import 'itinerary_model.dart';
import 'itinerary_view_page.dart';

class SavedItinerariesPage extends StatefulWidget {
  final UserModel user;

  const SavedItinerariesPage({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<SavedItinerariesPage> createState() => _SavedItinerariesPageState();
}

class _SavedItinerariesPageState extends State<SavedItinerariesPage> {
  final _storageService = ItineraryStorageService();
  bool _isLoading = true;
  List<ItineraryModel> _savedItineraries = [];

  @override
  void initState() {
    super.initState();
    _loadSavedItineraries();
  }

  Future<void> _loadSavedItineraries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final itineraries = await _storageService.getSavedItineraries();
      if (mounted) {
        setState(() {
          _savedItineraries = itineraries;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading saved itineraries: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteItinerary(String itineraryId) async {
    try {
      await _storageService.deleteItinerary(itineraryId);
      _loadSavedItineraries();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Itinerary deleted')),
        );
      }
    } catch (e) {
      print('Error deleting itinerary: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting itinerary: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text(
          'Saved Itineraries',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedItineraries.isEmpty
              ? _buildEmptyState()
              : _buildItineraryList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No saved itineraries yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your saved travel plans will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItineraryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _savedItineraries.length,
      itemBuilder: (context, index) {
        final itinerary = _savedItineraries[index];
        return _buildItineraryCard(itinerary);
      },
    );
  }

  Widget _buildItineraryCard(ItineraryModel itinerary) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _viewItinerary(itinerary),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location and date header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF2C2C2C),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itinerary.location,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${itinerary.days.length} days • Created on ${_formatDate(itinerary.generatedAt)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    onPressed: () => _confirmDelete(itinerary),
                  ),
                ],
              ),
            ),
            
            // Itinerary preview
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preview of first day
                  if (itinerary.days.isNotEmpty) ...[
                    Text(
                      'Day 1 Highlights:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...(_getHighlights(itinerary.days.first)),
                  ],
                  
                  const SizedBox(height: 16),
                  Center(
                    child: OutlinedButton(
                      onPressed: () => _viewItinerary(itinerary),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2C2C2C),
                        side: const BorderSide(color: Color(0xFF2C2C2C)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('View Full Itinerary'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _getHighlights(DayPlan day) {
    List<Activity> highlights = [];
    
    // Get one activity from each time slot as a highlight
    day.schedule.forEach((timeSlot, activities) {
      if (activities.isNotEmpty) {
        highlights.add(activities.first);
      }
    });
    
    // Limit to 3 highlights
    highlights = highlights.take(3).toList();
    
    return highlights.map((activity) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _getIconForActivityType(activity.type),
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                activity.name,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  IconData _getIconForActivityType(String type) {
    switch (type.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'attraction':
        return Icons.photo_camera;
      case 'experience':
        return Icons.event;
      default:
        return Icons.place;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _viewItinerary(ItineraryModel itinerary) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItineraryViewPage(
          user: widget.user,
          itinerary: itinerary,
        ),
      ),
    );
  }

  void _confirmDelete(ItineraryModel itinerary) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Itinerary?'),
        content: Text(
          'Are you sure you want to delete your ${itinerary.location} itinerary? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteItinerary(itinerary.location);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}