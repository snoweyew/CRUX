import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/models/user_model.dart';
import '../../shared/services/navigation_service.dart';
import '../../shared/services/recommendation_service.dart';
import '../../shared/config/app_config.dart';
import '../itinerary_personalization/itinerary_model.dart';
import 'cart_item.dart'; // Keep this import

// Import the new view files
import 'views/attraction_view.dart';
import 'views/event_view.dart';
import 'views/cart_view.dart';
import 'views/activity_view.dart';
import 'views/food_view.dart';
import 'views/recommendation_list_view_base.dart'; // For typedefs if needed directly

class RecommendationPage extends StatefulWidget {
  final UserModel user;
  final NavigationService navigationService;
  final RecommendationService recommendationService; // Added
  final ItineraryModel? itinerary;

  const RecommendationPage({
    Key? key,
    required this.user,
    required this.navigationService,
    required this.recommendationService, // Added
    required this.itinerary,
  }) : super(key: key);

  @override
  State<RecommendationPage> createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> with SingleTickerProviderStateMixin {
  final List<String> _categories = ['Attractions', 'Events', 'Cart', 'Activities', 'Food'];
  final List<IconData> _categoryIcons = [
    Icons.photo_camera,    // Attractions
    Icons.event,           // Events
    Icons.shopping_cart,   // Cart
    Icons.theater_comedy,  // Activities (was Experiences)
    Icons.restaurant,      // Food
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
    return WillPopScope(
      // Handle Android back button at the page level
      onWillPop: () async {
        // If modal cart is showing, handle back differently
        if (_selectedIndex == 2) {
          // If we're in the cart tab, check if we have any overlays showing
          final currentContext = context.findRenderObject()?.paintBounds;
          if (currentContext != null) {
            // Default to allowing back navigation
            return true;
          }
        }
        return true; // Allow normal back navigation by default
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBody: true,
        body: SafeArea(
          bottom: false,
          child: Column(
          children: [
              _buildAppBar(),
              const SizedBox(height: 8),
              Expanded(
                child: _buildSelectedCategoryView(),
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
      ),
    );
  }

  Widget _buildAppBar() {
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
          // Recommendations title (now on the left)
          Text(
            'Recommendations',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(), // Push cart icon to the right
          // Shopping cart icon on the right with cart item counter
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () {
                  // Navigate to the cart tab directly instead of showing a popup
                  setState(() {
                    _selectedIndex = 2; // Cart is at index 2
                  });
                  // Trigger animation for content change
                  _animationController.reset();
                  _animationController.forward();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 28,
              ),
              if (_cartItems.isNotEmpty)
                Positioned(
                  right: -5,
                  top: -5,
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
      ),
    );
  }

  void _addToCart(Map<String, String> product) {
    // Show a quantity selector dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int quantity = 1;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Add to Cart',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (product['imageUrl'] != null && product['imageUrl']!.isNotEmpty)
                      Container(
                        height: 120,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(product['imageUrl']!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    Text(
                      product['name']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'RM ${product['price']!}',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            if (quantity > 1) {
                              setState(() {
                                quantity--;
                              });
                            }
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            quantity.toString(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            setState(() {
                              quantity++;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add to Cart'),
                  onPressed: () {
                    Navigator.of(context).pop(quantity);
                  },
                ),
              ],
            );
          },
        );
      },
    ).then((selectedQuantity) {
      if (selectedQuantity != null) {
        _addItemsToCart(product, selectedQuantity);
      }
    });
  }

  // Actual method to add items to the cart with specified quantity
  void _addItemsToCart(Map<String, String> product, int quantity) {
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
          quantity: quantity,
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
          quantity: existingItem.quantity + quantity,
          imageUrl: existingItem.imageUrl, // Keep existing imageUrl
        );
      }
    });

    // Show notification that item was added
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $quantity item${quantity > 1 ? 's' : ''} to cart'),
        duration: const Duration(seconds: 1),
      ),
    );
    
    // Show cart badge animation
    setState(() {});
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
  
  Widget _buildSelectedCategoryView() {
    if (_selectedCity == null || _selectedCity!.isEmpty) {
      return const Center(
        child: Text('No city selected. Please go back and select a destination.'),
      );
    }

    // Use the public view widgets imported from separate files
    switch (_selectedIndex) {
      case 0: // Attractions
        return AttractionView(
          key: const ValueKey('attractions'),
          recommendationService: widget.recommendationService,
          selectedCity: _selectedCity!,
          fadeAnimation: _fadeAnimation,
          cardBuilder: _buildRecommendationCard,
        );
      case 1: // Events
        return EventView(
          key: const ValueKey('events'),
          recommendationService: widget.recommendationService,
          selectedCity: _selectedCity!,
          fadeAnimation: _fadeAnimation,
          cardBuilder: _buildRecommendationCard,
        );
      case 2: // Cart - Updated to work with new stateful CartView
        // Use a special key with 'checkout' when coming from checkout flow
        final bool isCheckoutFlow = _selectedIndex == 2 && _cartItems.isNotEmpty;
        final String keyValue = isCheckoutFlow 
            ? 'cart-checkout-${DateTime.now().millisecondsSinceEpoch}'
            : 'cart-${DateTime.now().millisecondsSinceEpoch}';
            
        return CartView(
          key: ValueKey(keyValue), // Use unique key to force rebuild with checkout flag
          recommendationService: widget.recommendationService,
          user: widget.user, // Pass the user model
          selectedCity: _selectedCity!,
          fadeAnimation: _fadeAnimation,
          onAddToCart: _addToCart,
          shoppingCardBuilder: _buildShoppingCard,
          cartItems: _cartItems,
          onCartUpdated: _updateCartItems,
        );
      case 3: // Activities
        return ActivityView(
          key: const ValueKey('activities'),
          recommendationService: widget.recommendationService,
          selectedCity: _selectedCity!,
          fadeAnimation: _fadeAnimation,
          cardBuilder: _buildRecommendationCard,
        );
      case 4: // Food
        return FoodView(
          key: const ValueKey('food'),
          recommendationService: widget.recommendationService,
          selectedCity: _selectedCity!,
          fadeAnimation: _fadeAnimation,
          cardBuilder: _buildRecommendationCard,
        );
      default:
        return const Center(child: Text('Invalid category selected.'));
    }
  }

  // Helper method to build the standard recommendation card (remains in this state class)
  Widget _buildRecommendationCard(BuildContext context, Map<String, String> recommendation) {
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

  // Helper method to build the shopping card (remains in this state class)
  Widget _buildShoppingCard(BuildContext context, Map<String, String> recommendation, ValueChanged<Map<String, String>> onAddToCart) {
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
                      heroTag: null, // Avoid hero tag conflicts if multiple cards
                      onPressed: () => onAddToCart(recommendation), // Use the passed callback
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

  // New method to update cart items from CartView
  void _updateCartItems(List<dynamic> updatedItems) {
    setState(() {
      _cartItems = List.from(updatedItems);
    });
  }

  void _showCheckout() {
    // Simply navigate to the Cart tab
    setState(() {
      _selectedIndex = 2; // Set to Cart tab
    });
    
    // Trigger animation for content change
    _animationController.reset();
    _animationController.forward();
    
    // Use a post-frame callback to show checkout options in the CartView
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Find the current CartView state and trigger its checkout flow
        final currentContext = context.findRenderObject()?.paintBounds;
        if (currentContext != null) {
          // Notify the user that they can proceed with checkout
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select an airport for pickup'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }
}