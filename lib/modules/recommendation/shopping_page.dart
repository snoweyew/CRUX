import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/models/user_model.dart';
import '../../shared/services/navigation_service.dart';
import '../../shared/services/mock_data_service.dart';
import '../../shared/services/recommendation_service.dart';
import '../../shared/config/app_config.dart';
import '../itinerary_personalization/itinerary_model.dart';
import 'base_recommendation_page.dart';
import 'cart_item.dart';

class ShoppingPage extends BaseRecommendationPage {
  const ShoppingPage({
    Key? key,
    required UserModel user,
    required NavigationService navigationService,
    required MockDataService mockDataService,
    required ItineraryModel? itinerary,
    required RecommendationService recommendationService,
  }) : super(
          key: key,
          user: user,
          navigationService: navigationService,
          mockDataService: mockDataService,
          itinerary: itinerary,
          recommendationService: recommendationService,
        );

  @override
  State<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends BaseRecommendationPageState<ShoppingPage> {
  List<CartItem> _cartItems = [];

  @override
  String getPageTitle() {
    return 'Shopping';
  }

  @override
  IconData getPageIcon() {
    return Icons.shopping_bag;
  }

  @override
  int getCategoryIndex() {
    return 4; // Shopping is the fifth category
  }

  @override
  String getCategoryImage() {
    return 'assets/images/shopping_placeholder.jpg';
  }

  @override
  Widget buildAppBar() {
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
          const Icon(Icons.shopping_bag, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Text(
            'Shopping',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
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
      ),
    );
  }

  @override
  Widget buildRecommendationsList() {
    final recommendations = getMockRecommendations();
    
    return FadeTransition(
      opacity: fadeAnimation,
      child: GridView.builder(
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
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 200 + (index * 100)),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: child,
              );
            },
            child: _buildShoppingCard(recommendation),
          );
        },
      ),
    );
  }

  Widget _buildShoppingCard(Map<String, String> recommendation) {
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
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                      image: DecorationImage(
                        image: AssetImage(getCategoryImage()),
                        fit: BoxFit.cover,
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
                  mainAxisSize: MainAxisSize.min,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'RM ${recommendation['price']!}',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          Icons.location_on,
                          size: 10,
                          color: Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart(Map<String, String> product) {
    setState(() {
      final existingItem = _cartItems.firstWhere(
        (item) => item.productId == product['id'],
        orElse: () => CartItem(
          productId: product['id']!,
          name: product['name']!,
          location: product['location']!,
          price: double.parse(product['price']!),
          quantity: 0,
        ),
      );

      if (existingItem.quantity == 0) {
        _cartItems.add(CartItem(
          productId: product['id']!,
          name: product['name']!,
          location: product['location']!,
          price: double.parse(product['price']!),
          quantity: 1,
        ));
      } else {
        final index = _cartItems.indexOf(existingItem);
        _cartItems[index] = CartItem(
          productId: existingItem.productId,
          name: existingItem.name,
          location: existingItem.location,
          price: existingItem.price,
          quantity: existingItem.quantity + 1,
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
              child: _cartItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Your cart is empty',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _cartItems.length,
                      itemBuilder: (context, index) {
                        final item = _cartItems[index];
                        return Card(
                          child: ListTile(
                            title: Text(item.name),
                            subtitle: Text('RM ${item.price.toStringAsFixed(2)}'),
                            trailing: Text('x${item.quantity}'),
                          ),
                        );
                      },
                    ),
            ),
            if (_cartItems.isNotEmpty)
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
      _cartItems = []; // Reset to empty list
    });

    // Show success dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
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
              // Close the confirmation dialog
              Navigator.of(dialogContext).pop();
              
              // Navigate back to the shopping page with a fresh state
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation1, animation2) => ShoppingPage(
                    user: widget.user,
                    navigationService: widget.navigationService,
                    mockDataService: widget.mockDataService,
                    itinerary: widget.itinerary,
                    recommendationService: widget.recommendationService,
                  ),
                  transitionDuration: Duration.zero,
                ),
              );
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

  @override
  List<Map<String, String>> getMockRecommendations() {
    return [
      {
        'id': 'craft1',
        'name': 'Traditional Pua Kumbu Textile',
        'description': 'Hand-woven ceremonial blanket with intricate patterns',
        'location': 'Main Bazaar',
        'price': '299.00'
      },
      {
        'id': 'craft2',
        'name': 'Orang Ulu Beaded Necklace',
        'description': 'Handcrafted beaded jewelry with traditional motifs',
        'location': 'Kuching Old Town',
        'price': '89.00'
      },
      {
        'id': 'craft3',
        'name': 'Bidayuh Bamboo Basket',
        'description': 'Traditional hand-woven bamboo basket',
        'location': 'Satok Market',
        'price': '149.00'
      },
      {
        'id': 'craft4',
        'name': 'Sarawak Black Pepper Products',
        'description': 'Premium grade Sarawak black pepper',
        'location': 'Carpenter Street',
        'price': '25.00'
      },
      {
        'id': 'craft5',
        'name': 'Melanau Terendak Hat',
        'description': 'Traditional conical hat made from sago leaves',
        'location': 'India Street',
        'price': '79.00'
      },
      {
        'id': 'craft6',
        'name': 'Iban Silver Jewelry Set',
        'description': 'Handcrafted silver jewelry with tribal motifs',
        'location': 'Main Bazaar',
        'price': '399.00'
      }
    ];
  }

  @override
  Future<List<Map<String, String>>> getRecommendations() async {
    if (AppConfig.enableMockData) {
      return widget.recommendationService.getMockRecommendations('shopping');
    }
    try {
      return await widget.recommendationService.getShopping();
    } catch (e) {
      // Fallback to mock data if API fails
      return widget.recommendationService.getMockRecommendations('shopping');
    }
  }
} 