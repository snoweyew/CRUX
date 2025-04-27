import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/models/user_model.dart';
import '../../shared/services/navigation_service.dart';
// import '../../shared/services/mock_data_service.dart'; // No longer needed for recommendations
import '../../shared/services/recommendation_service.dart'; // Import RecommendationService
import '../../shared/config/app_config.dart'; // Import AppConfig if needed for mock data flag
import '../itinerary_personalization/itinerary_model.dart';
import 'cart_item.dart'; // Ensure cart_item.dart is imported if it's separate

class CartItem {
  final String productId;
  final String name;
  final String location;
  final double price;
  final int quantity;
  final String? imageUrl; // Add imageUrl field

  CartItem({
    required this.productId,
    required this.name,
    required this.location,
    required this.price,
    required this.quantity,
    this.imageUrl, // Initialize imageUrl
  });
}

class RecommendationPage extends StatefulWidget {
  final UserModel user;
  final NavigationService navigationService;
  // final MockDataService mockDataService; // Removed
  final RecommendationService recommendationService; // Added
  final ItineraryModel? itinerary;

  const RecommendationPage({
    Key? key,
    required this.user,
    required this.navigationService,
    // required this.mockDataService, // Removed
    required this.recommendationService, // Added
    required this.itinerary,
  }) : super(key: key);

  @override
  State<RecommendationPage> createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> with SingleTickerProviderStateMixin {
  final List<String> _categories = ['Events', 'Food', 'Experiences', 'Attractions', 'Shopping'];
  final List<IconData> _categoryIcons = [
    Icons.event,
    Icons.restaurant,
    Icons.theater_comedy,
    Icons.photo_camera,
    Icons.shopping_bag,
  ];
  int _selectedIndex = 0;
  List<CartItem> _cartItems = [];
  String? _selectedCity; // Store the selected city
  
  // Animation controller for page transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.user.selectedCity; // Get the city from the user model
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
        children: [
            _buildAppBar(),
            const SizedBox(height: 8),
            Expanded(
              child: _buildRecommendationsList(), // This will now use FutureBuilder
                ),
              ],
            ),
          ),
      bottomNavigationBar: Container(
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                _categories.length,
                (index) => _buildNavItem(index),
              ),
                        ),
                      ),
                    ),
                  ),
                );
  }

  Widget _buildAppBar() {
    final isShoppingCategory = _categories[_selectedIndex].toLowerCase() == 'shopping';
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF2C2C2C),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.recommend, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Text(
            'Recommendations',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isShoppingCategory) ...[
            const Spacer(),
            Stack(
          children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart, color: Colors.white),
                  onPressed: () => _showCart(),
                ),
            if (_cartItems.isNotEmpty)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                  ),
                  child: Text(
                    _cartItems.length.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                          fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
          ],
        ],
      ),
    );
  }

  void _showCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.black12)),
              ),
              child: Row(
                children: [
                  const Text(
                    'Shopping Cart',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _cartItems.length,
                itemBuilder: (context, index) {
                  final item = _cartItems[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: item.imageUrl != null && item.imageUrl!.isNotEmpty
                          ? ClipRRect( // Rounded corners for image
                              borderRadius: BorderRadius.circular(4.0),
                              child: Image.network(
                                item.imageUrl!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox(width: 50, height: 50, child: Icon(Icons.broken_image, size: 24)),
                                loadingBuilder: (context, child, progress) =>
                                    progress == null ? child : const SizedBox(width: 50, height: 50, child: Center(child: CircularProgressIndicator())),
                              ),
                            )
                          : const SizedBox(width: 50, height: 50, child: Icon(Icons.image_not_supported)), // Placeholder if no image
                      title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('RM ${item.price.toStringAsFixed(2)}'),
                      trailing: Text('x${item.quantity}', style: const TextStyle(fontSize: 16)),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'RM ${_calculateTotal().toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showCheckout(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('Proceed to Checkout'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCheckout() {
    final airports = [
      'Kuching International Airport',
      'Sibu Airport',
      'Miri Airport',
      'Bintulu Airport',
    ];
    String? selectedAirport;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Cash on Delivery'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select pickup location:'),
              const SizedBox(height: 8),
              DropdownButton<String>(
                isExpanded: true,
                value: selectedAirport,
                hint: const Text('Select Airport'),
                items: airports.map((airport) {
                  return DropdownMenuItem(
                    value: airport,
                    child: Text(airport),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedAirport = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedAirport == null
                  ? null
                  : () {
                      // First close the checkout dialog
                      Navigator.pop(context);
                      // Then close the cart
                      Navigator.pop(context);
                      // Finally process the order with the selected airport
                      _processOrder(selectedAirport!);
                    },
              child: const Text('Confirm Order'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _processOrder(String airport) {
    // Clear the cart first
    setState(() {
      _cartItems.clear();
    });

    // Show success dialog
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap OK to dismiss
      builder: (BuildContext dialogContext) => AlertDialog(  // Use a named context
        title: const Text('Order Confirmed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your order has been confirmed for pickup at:'),
            const SizedBox(height: 8),
            Text(
              airport,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            const Text('You can collect your items at the airport counter.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Just pop the confirmation dialog using the dialog's context
              Navigator.of(dialogContext).pop();
              
              // Use a post-frame callback to ensure we're back on the recommendation page
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // Navigate to the current page to refresh it (forcing a rebuild)
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecommendationPage(
                      user: widget.user,
                      navigationService: widget.navigationService,
                      recommendationService: widget.recommendationService,
                      itinerary: widget.itinerary,
                    ),
                  ),
                );
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  double _calculateTotal() {
    return _cartItems.fold(0, (total, item) => total + (item.price * item.quantity));
  }

  void _addToCart(Map<String, String> product) {
    setState(() {
      final existingItemIndex = _cartItems.indexWhere(
        (item) => item.productId == product['id'],
      );

      final imageUrl = product['imageUrl']; // Get image URL from product data

      if (existingItemIndex == -1) {
        // Item not in cart, add new
        _cartItems.add(CartItem(
          productId: product['id']!,
          name: product['name']!,
          location: product['location']!,
          price: double.parse(product['price']!),
          quantity: 1,
          imageUrl: imageUrl, // Pass imageUrl
        ));
      } else {
        // Item exists, update quantity
        final existingItem = _cartItems[existingItemIndex];
        _cartItems[existingItemIndex] = CartItem(
          productId: existingItem.productId,
          name: existingItem.name,
          location: existingItem.location,
          price: existingItem.price,
          quantity: existingItem.quantity + 1,
          imageUrl: existingItem.imageUrl, // Keep existing imageUrl
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Added to cart'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        if (_selectedIndex != index) {
          HapticFeedback.selectionClick();
        setState(() {
          _selectedIndex = index;
        });
          // Trigger animation for content change
          _animationController.reset();
          _animationController.forward();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _categoryIcons[index],
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              _categories[index],
              style: TextStyle(
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRecommendationsList() {
    if (_selectedCity == null || _selectedCity!.isEmpty) {
      return const Center(
        child: Text('No city selected. Please go back and select a destination.'),
      );
    }

    final category = _categories[_selectedIndex].toLowerCase();

    // Use FutureBuilder to fetch recommendations from the service
    return FutureBuilder<List<Map<String, String>>>(
      // Fetch data using the service. Assuming mock data for now.
      // Replace with API calls if AppConfig.enableMockData is false and API supports city filtering.
      future: Future.value(widget.recommendationService.getMockRecommendations(category, city: _selectedCity)),
      // Example using API call (if API supported city filtering - currently it doesn't seem to):
      // future: AppConfig.enableMockData
      //     ? Future.value(widget.recommendationService.getMockRecommendations(category, city: _selectedCity))
      //     : widget.recommendationService.fetchRecommendations(category, city: _selectedCity), // Hypothetical API call
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading recommendations: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text('No recommendations found for $_selectedCity in the $category category.'),
          );
        }

        final recommendations = snapshot.data!;
        final isShoppingCategory = category == 'shopping';

        // Use FadeTransition with the fetched data
        return FadeTransition(
          opacity: _fadeAnimation, // Consider resetting animation on category change
          child: isShoppingCategory
              ? GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: recommendations.length,
                  itemBuilder: (context, index) {
                    final recommendation = recommendations[index];
                    // Using simple Opacity, consider removing TweenAnimationBuilder here
                    // if FutureBuilder handles the loading state.
                    return Opacity(
                       opacity: 1.0, // Or keep TweenAnimationBuilder if preferred
                       child: _buildShoppingCard(recommendation),
                    );
                  },
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: recommendations.length,
                  itemBuilder: (context, index) {
                    final recommendation = recommendations[index];
                    // Using simple Opacity, consider removing TweenAnimationBuilder here
                    return Opacity(
                      opacity: 1.0, // Or keep TweenAnimationBuilder if preferred
                      child: _buildRecommendationCard(recommendation),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildRecommendationCard(Map<String, String> recommendation) {
    final screenHeight = MediaQuery.of(context).size.height;
    final double cardHeight = screenHeight * 0.22; // Adjusted to 22% of screen height
    final imageUrl = recommendation['imageUrl']; // Get image URL
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          // Show detailed view (to be implemented)
        },
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: cardHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              // Image section (3/4)
              Expanded(
                flex: 7, // Adjusted ratio
                child: ClipRRect( // Apply clipping directly to the image container
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Container(
                    color: Colors.grey[200], // Background color for loading/error states
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover, // Ensure image covers the container
                            width: double.infinity, // Ensure it takes full width
                            // Add loading/error builders for better UX
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(child: CircularProgressIndicator());
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(child: Icon(Icons.broken_image, color: Colors.grey));
                            },
                          )
                        : const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)), // Fallback
                  ),
                ),
              ),
              // Text section (1/4)
              Expanded(
                flex: 3, // Adjusted ratio
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                      Text(
                        recommendation['name']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                            size: 12,
                            color: Theme.of(context).primaryColor,
                    ),
                          const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                              recommendation['location']!,
                        style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 10,
                        ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
          ),
      ),
    );
  }
  
  Widget _buildShoppingCard(Map<String, String> recommendation) {
    final imageUrl = recommendation['imageUrl']; // Get image URL

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          // Show product details
        },
        borderRadius: BorderRadius.circular(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Image section
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  ClipRRect( // Apply clipping directly
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                    child: Container(
                      color: Colors.grey[200], // Background color
                      child: SizedBox.expand( // Ensure image tries to fill container
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover, // Ensure image covers the container
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(child: CircularProgressIndicator());
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(child: Icon(Icons.broken_image, color: Colors.grey));
                                },
                              )
                            : const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)), // Fallback
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: FloatingActionButton.small(
                      heroTag: null,
                      onPressed: () => _addToCart(recommendation),
                      backgroundColor: Theme.of(context).primaryColor,
                      child: const Icon(Icons.add_shopping_cart, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            // Info section
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommendation['name']!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                                Text(
                      'RM ${recommendation['price']!}',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 14,
                                    fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 10,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            recommendation['location']!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}