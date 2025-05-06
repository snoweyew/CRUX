import 'package:flutter/material.dart';
import '../../../shared/services/recommendation_service.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/models/user_model.dart';

// Type definition for the shopping card builder function
typedef ShoppingCardBuilder = Widget Function(BuildContext context, Map<String, String> recommendation, ValueChanged<Map<String, String>> onAddToCart);

class CartView extends StatefulWidget {
  final RecommendationService recommendationService;
  final UserModel user; // Add user parameter
  final String selectedCity;
  final Animation<double> fadeAnimation;
  final ValueChanged<Map<String, String>> onAddToCart;
  final ShoppingCardBuilder shoppingCardBuilder;
  final List<dynamic> cartItems;
  final Function(List<dynamic>) onCartUpdated;

  const CartView({
    Key? key,
    required this.recommendationService,
    required this.user, // Add required user model
    required this.selectedCity,
    required this.fadeAnimation,
    required this.onAddToCart,
    required this.shoppingCardBuilder,
    required this.cartItems,
    required this.onCartUpdated,
  }) : super(key: key);

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  // List of airports for checkout
  final List<String> airports = [
    'Kuching International Airport',
    'Miri Airport',
    'Sibu Airport',
    'Bintulu Airport'
  ];
  
  String? _selectedAirport;
  bool _isProcessingOrder = false;
  bool _showOrderSuccess = false;
  int? _orderId;
  bool _shouldTriggerCheckout = false;
  
  @override
  void initState() {
    super.initState();
    // Check if there are items in the cart and trigger checkout after a short delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.cartItems.isNotEmpty && mounted) {
        // Use this flag to prevent multiple checkout dialogs
        final String uniqueKey = (widget.key as ValueKey?)?.value?.toString() ?? '';
        if (uniqueKey.contains('checkout')) {
          setState(() {
            _shouldTriggerCheckout = true;
          });
          
          // Add a small delay to allow the UI to render first
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted && _shouldTriggerCheckout) {
              _showCheckoutOptions();
              _shouldTriggerCheckout = false;
            }
          });
        }
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    print('CartView is being built'); // Debug print
    const categoryKey = 'shopping';
    
    // Calculate total price
    double totalPrice = 0;
    for (final item in widget.cartItems) {
      totalPrice += (item.price * item.quantity);
    }

    // Wrap with WillPopScope to handle Android back button properly
    return WillPopScope(
      onWillPop: () async {
        // If showing checkout overlay, close it instead of navigating back
        if (_isProcessingOrder && !_showOrderSuccess) {
          setState(() {
            _isProcessingOrder = false;
          });
          return false; // Prevent default back behavior
        }
        
        // If showing success overlay, complete the order
        if (_showOrderSuccess) {
          _completeOrder();
          return false; // Prevent default back behavior
        }
        
        // Default behavior - allow back navigation
        return true;
      },
      child: Stack(
        children: [
          // Main cart content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Souvenir Shop',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                      onPressed: () {
                        setState(() {
                          // Force rebuild
                        });
                      },
                    ),
                  ],
                ),
              ),
              
              // Cart items section
              if (widget.cartItems.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'Your cart is empty',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Browse products and add items to your cart',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Your Cart (${widget.cartItems.length} items)',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                widget.onCartUpdated([]);
                                setState(() {});
                              },
                              icon: const Icon(Icons.delete_outline, size: 16),
                              label: const Text('Clear All'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Cart items list
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: widget.cartItems.length,
                          itemBuilder: (context, index) {
                            final item = widget.cartItems[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Row(
                                  children: [
                                    // Product image
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: SizedBox(
                                        width: 60,
                                        height: 60,
                                        child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                                          ? Image.network(
                                              item.imageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const Icon(
                                                Icons.image_not_supported,
                                                size: 24,
                                              ),
                                            )
                                          : const Icon(Icons.image_not_supported, size: 24),
                                      ),
                                    ),
                                    
                                    // Product details
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'RM ${item.price.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                color: Theme.of(context).primaryColor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              item.location,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    
                                    // Quantity controls
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline),
                                          onPressed: () {
                                            final updatedItems = List.of(widget.cartItems);
                                            if (item.quantity > 1) {
                                              final updatedItem = item.copyWith(quantity: item.quantity - 1);
                                              updatedItems[index] = updatedItem;
                                            } else {
                                              updatedItems.removeAt(index);
                                            }
                                            widget.onCartUpdated(updatedItems);
                                            setState(() {});
                                          },
                                          iconSize: 20,
                                          splashRadius: 20,
                                        ),
                                        Text(
                                          '${item.quantity}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline),
                                          onPressed: () {
                                            final updatedItems = List.of(widget.cartItems);
                                            final updatedItem = item.copyWith(quantity: item.quantity + 1);
                                            updatedItems[index] = updatedItem;
                                            widget.onCartUpdated(updatedItems);
                                            setState(() {});
                                          },
                                          iconSize: 20,
                                          splashRadius: 20,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      // Order summary and checkout button
                      if (widget.cartItems.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, -5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'RM ${totalPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _showCheckoutOptions,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2C2C2C),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: const Text('Checkout'),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                
              // Products section
              if (widget.cartItems.isEmpty) 
                Expanded(
                  child: FutureBuilder<List<Map<String, String>>>(
                    future: widget.recommendationService.fetchRecommendations(categoryKey, city: widget.selectedCity),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error loading items: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.shopping_cart, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                'No products found for ${widget.selectedCity}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Check back later for new products',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      final recommendations = snapshot.data!;
                      
                      return FadeTransition(
                        opacity: widget.fadeAnimation,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: recommendations.length,
                          itemBuilder: (context, index) {
                            final recommendation = recommendations[index];
                            return widget.shoppingCardBuilder(context, recommendation, widget.onAddToCart);
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
          
          // Checkout overlay
          if (_isProcessingOrder && !_showOrderSuccess)
            _buildCheckoutOverlay(),
            
          // Order success overlay
          if (_showOrderSuccess)
            _buildOrderSuccessOverlay(),
        ],
      ),
    );
  }
  
  void _showCheckoutOptions() {
    setState(() {
      _selectedAirport = null;
      _isProcessingOrder = true;
    });
  }
  
  Widget _buildCheckoutOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flight_takeoff, color: Color(0xFF2C2C2C)),
                    const SizedBox(width: 8),
                    const Text(
                      'Airport Pickup',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _isProcessingOrder = false;
                        });
                      },
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      iconSize: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select airport for pickup:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      border: InputBorder.none,
                      hintText: 'Select airport',
                    ),
                    value: _selectedAirport,
                    items: airports.map((airport) {
                      return DropdownMenuItem<String>(
                        value: airport,
                        child: Text(airport),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        _selectedAirport = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedAirport == null ? null : _processOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C2C2C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: const Text('Confirm Order'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Future<void> _processOrder() async {
    // Generate random order ID
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomOrderId = 100000 + timestamp % 900000;
    
    // Simulate processing delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    setState(() {
      _orderId = randomOrderId;
      _showOrderSuccess = true;
      _isProcessingOrder = false;
    });
  }
  
  Widget _buildOrderSuccessOverlay() {
    final orderDate = DateTime.now();
    final formattedDate = '${orderDate.day}/${orderDate.month}/${orderDate.year}';
    
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Order Successful!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _buildOrderDetailRow('Order ID:', '#$_orderId'),
                        const SizedBox(height: 8),
                        _buildOrderDetailRow('Date:', formattedDate),
                        const SizedBox(height: 8),
                        _buildOrderDetailRow('Pickup Location:', _selectedAirport!),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Please show this order confirmation at the airport duty-free counter to collect your items.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _completeOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C2C2C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildOrderDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
  
  void _completeOrder() {
    // Clear the cart and reset the view
    widget.onCartUpdated([]);
    
    setState(() {
      _showOrderSuccess = false;
      _isProcessingOrder = false;
      _selectedAirport = null;
    });
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order placed successfully!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
