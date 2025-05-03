// filepath: /home/yew/Desktop/CRUX/lib/modules/welcome/visitor_type_selection_page.dart
import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // Remove Firestore import
import 'package:supabase_flutter/supabase_flutter.dart'; // Add Supabase import
import '../../shared/services/navigation_service.dart';
import '../../shared/services/itinerary_storage_service.dart';
import '../../shared/models/user_model.dart';

class VisitorTypeSelectionPage extends StatefulWidget {
  final NavigationService navigationService;
  final UserModel user;

  const VisitorTypeSelectionPage({
    Key? key,
    required this.navigationService,
    required this.user,
  }) : super(key: key);

  @override
  State<VisitorTypeSelectionPage> createState() => _VisitorTypeSelectionPageState();
}

class _VisitorTypeSelectionPageState extends State<VisitorTypeSelectionPage> {
  String? _selectedType;
  bool _isLoading = false;
  String _name = '';
  String? _selectedState;
  String? _selectedCountry;
  bool _hasSavedItineraries = false;
  final TextEditingController _nameController = TextEditingController();
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Remove Firestore instance
  final _supabase = Supabase.instance.client; // Add Supabase client instance
  final _itineraryStorage = ItineraryStorageService(); // Add storage service
  
  final List<String> _malaysianStates = [
    'Johor',
    'Kedah',
    'Kelantan',
    'Melaka',
    'Negeri Sembilan',
    'Pahang',
    'Perak',
    'Perlis',
    'Pulau Pinang',
    'Sabah',
    'Sarawak',
    'Selangor',
    'Terengganu',
    'Kuala Lumpur',
    'Labuan',
    'Putrajaya',
  ];

  final List<String> _countries = [
    'Afghanistan', 'Albania', 'Algeria', 'Andorra', 'Angola', 'Antigua and Barbuda', 'Argentina', 'Armenia', 'Australia', 'Austria',
    'Azerbaijan', 'Bahamas', 'Bahrain', 'Bangladesh', 'Barbados', 'Belarus', 'Belgium', 'Belize', 'Benin', 'Bhutan',
    'Bolivia', 'Bosnia and Herzegovina', 'Botswana', 'Brazil', 'Brunei', 'Bulgaria', 'Burkina Faso', 'Burundi', 'Cabo Verde',
    'Cambodia', 'Cameroon', 'Canada', 'Central African Republic', 'Chad', 'Chile', 'China', 'Colombia', 'Comoros',
    'Congo', 'Costa Rica', 'Croatia', 'Cuba', 'Cyprus', 'Czech Republic', 'Denmark', 'Djibouti', 'Dominica',
    'Dominican Republic', 'Ecuador', 'Egypt', 'El Salvador', 'Equatorial Guinea', 'Eritrea', 'Estonia', 'Eswatini',
    'Ethiopia', 'Fiji', 'Finland', 'France', 'Gabon', 'Gambia', 'Georgia', 'Germany', 'Ghana', 'Greece', 'Grenada',
    'Guatemala', 'Guinea', 'Guinea-Bissau', 'Guyana', 'Haiti', 'Honduras', 'Hungary', 'Iceland', 'India', 'Indonesia',
    'Iran', 'Iraq', 'Ireland', 'Israel', 'Italy', 'Jamaica', 'Japan', 'Jordan', 'Kazakhstan', 'Kenya', 'Kiribati',
    'Korea, North', 'Korea, South', 'Kosovo', 'Kuwait', 'Kyrgyzstan', 'Laos', 'Latvia', 'Lebanon', 'Lesotho', 'Liberia',
    'Libya', 'Liechtenstein', 'Lithuania', 'Luxembourg', 'Madagascar', 'Malawi', 'Maldives', 'Mali', 'Malta',
    'Marshall Islands', 'Mauritania', 'Mauritius', 'Mexico', 'Micronesia', 'Moldova', 'Monaco', 'Mongolia', 'Montenegro',
    'Morocco', 'Mozambique', 'Myanmar', 'Namibia', 'Nauru', 'Nepal', 'Netherlands', 'New Zealand', 'Nicaragua', 'Niger',
    'Nigeria', 'North Macedonia', 'Norway', 'Oman', 'Pakistan', 'Palau', 'Palestine', 'Panama', 'Papua New Guinea',
    'Paraguay', 'Peru', 'Philippines', 'Poland', 'Portugal', 'Qatar', 'Romania', 'Russia', 'Rwanda', 'Saint Kitts and Nevis',
    'Saint Lucia', 'Saint Vincent and the Grenadines', 'Samoa', 'San Marino', 'Sao Tome and Principe', 'Saudi Arabia',
    'Senegal', 'Serbia', 'Seychelles', 'Sierra Leone', 'Singapore', 'Slovakia', 'Slovenia', 'Solomon Islands', 'Somalia',
    'South Africa', 'South Sudan', 'Spain', 'Sri Lanka', 'Sudan', 'Suriname', 'Sweden', 'Switzerland', 'Syria', 'Taiwan',
    'Tajikistan', 'Tanzania', 'Thailand', 'Timor-Leste', 'Togo', 'Tonga', 'Trinidad and Tobago', 'Tunisia', 'Turkey',
    'Turkmenistan', 'Tuvalu', 'Uganda', 'Ukraine', 'United Arab Emirates', 'United Kingdom', 'United States', 'Uruguay',
    'Uzbekistan', 'Vanuatu', 'Vatican City', 'Venezuela', 'Vietnam', 'Yemen', 'Zambia', 'Zimbabwe'
  ];

  @override
  void initState() {
    super.initState();
    _checkSavedItineraries();
  }
  
  Future<void> _checkSavedItineraries() async {
    final hasSaved = await _itineraryStorage.hasSavedItineraries();
    if (mounted) {
      setState(() {
        _hasSavedItineraries = hasSaved;
      });
    }
  }

  // --- Replace _recordVisitorStats with Supabase logic ---
  Future<void> _recordVisitorStats(UserModel updatedUser) async {
    final city = updatedUser.selectedCity;
    if (city == null || city.isEmpty) {
      print('Error: City is null or empty, cannot record stats.');
      return;
    }

    // ...existing visitor stats code...
  }

  Future<void> _handleContinue() async {
    // ...existing visitor type validation code...
  }
  
  void _viewSavedItineraries() {
    final updatedUser = widget.user.copyWith(
      visitorType: _selectedType,
      name: _name,
      state: _selectedType == 'Malaysian' ? _selectedState : null,
      country: _selectedType == 'Foreign' ? _selectedCountry : null,
    );
    
    widget.navigationService.navigateTo(
      '/saved_itineraries',
      arguments: updatedUser,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C2C2C)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Welcome to ${widget.user.selectedCity}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please select your visitor type',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 40),
                
                // ...existing visitor type selection code...
                
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C2C2C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Create my trip!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                
                // Show saved itinerary button if available
                if (_hasSavedItineraries) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _viewSavedItineraries,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF2C2C2C), width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bookmark, color: Color(0xFF2C2C2C)),
                          SizedBox(width: 8),
                          Text(
                            'View Saved Itineraries',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C2C2C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ...existing widget building methods...
}