import 'package:flutter/material.dart';
import '../../shared/services/navigation_service.dart';
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
  final TextEditingController _nameController = TextEditingController();
  
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

  Future<void> _handleContinue() async {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select visitor type')),
      );
      return;
    }
    
    if (_name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    if (_selectedType == 'Malaysian' && _selectedState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your state')),
      );
      return;
    }

    if (_selectedType == 'Foreign' && _selectedCountry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your country')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Update the user with the selected visitor type and additional info
      final updatedUser = widget.user.copyWith(
        visitorType: _selectedType,
        name: _name,
        state: _selectedType == 'Malaysian' ? _selectedState : null,
        country: _selectedType == 'Foreign' ? _selectedCountry : null,
      );
      
      // Navigate directly to itinerary personalization for all users
      widget.navigationService.navigateToReplacement(
        '/itinerary_personalization',
        arguments: updatedUser,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
                
                // Malaysian option
                _buildVisitorTypeCard(
                  title: 'Malaysian',
                  description: 'For Malaysian citizens and residents',
                  icon: Icons.location_on,
                  isSelected: _selectedType == 'Malaysian',
                  onTap: () {
                    setState(() {
                      _selectedType = _selectedType != 'Malaysian' ? 'Malaysian' : null;
                      // Reset foreign country when switching to Malaysian
                      if (_selectedType == 'Malaysian') {
                        _selectedCountry = null;
                      }
                    });
                  },
                ),
                
                // Malaysian details section
                if (_selectedType == 'Malaysian') ...[
                  const SizedBox(height: 24),
                  _buildDetailsSection(
                    title: 'Your Details',
                    child: Column(
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.person),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _name = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedState,
                          decoration: InputDecoration(
                            labelText: 'State',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.location_city),
                          ),
                          items: _malaysianStates.map((state) {
                            return DropdownMenuItem(
                              value: state,
                              child: Text(state),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedState = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Foreign option
                _buildVisitorTypeCard(
                  title: 'Foreign',
                  description: 'For international visitors',
                  icon: Icons.flight,
                  isSelected: _selectedType == 'Foreign',
                  onTap: () {
                    setState(() {
                      _selectedType = _selectedType != 'Foreign' ? 'Foreign' : null;
                      // Reset Malaysian state when switching to Foreign
                      if (_selectedType == 'Foreign') {
                        _selectedState = null;
                      }
                    });
                  },
                ),

                // Foreign details section
                if (_selectedType == 'Foreign') ...[
                  const SizedBox(height: 24),
                  _buildDetailsSection(
                    title: 'Your Details',
                    child: Column(
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.person),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _name = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedCountry,
                          decoration: InputDecoration(
                            labelText: 'Country',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.public),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          items: _countries.map((country) {
                            return DropdownMenuItem<String>(
                              value: country,
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width - 120,
                                child: Text(
                                  country,
                                  style: const TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCountry = value;
                            });
                          },
                          icon: const Icon(Icons.arrow_drop_down, size: 20),
                          iconSize: 20,
                          menuMaxHeight: 300,
                          isExpanded: true,
                          itemHeight: 48,
                        ),
                      ],
                    ),
                  ),
                ],

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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisitorTypeCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2C2C2C).withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF2C2C2C) : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2C2C2C).withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFF2C2C2C) : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? Colors.black87 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? const Color(0xFF2C2C2C) : Colors.grey,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
} 