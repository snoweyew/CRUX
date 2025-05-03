import 'package:flutter/material.dart';
import '../../../shared/services/recommendation_service.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/config/app_config.dart';

// Type definition for the shopping card builder function
typedef ShoppingCardBuilder = Widget Function(BuildContext context, Map<String, String> recommendation, ValueChanged<Map<String, String>> onAddToCart);

// List of airports for checkout
const List<String> airports = [
  'Kuching International Airport',
  'Miri Airport',
  'Sibu Airport',
  'Bintulu Airport'
];

// View for Cart (formerly Shopping) - Uses GridView
class CartView extends StatelessWidget {
  final RecommendationService recommendationService;
  final String selectedCity;
  final Animation<double> fadeAnimation;
  final ValueChanged<Map<String, String>> onAddToCart; // Callback to add item
  final ShoppingCardBuilder shoppingCardBuilder; // Function to build shopping card

  const CartView({
    Key? key,
    required this.recommendationService,
    required this.selectedCity,
    required this.fadeAnimation,
    required this.onAddToCart,
    required this.shoppingCardBuilder,
  }) : super(key: key);

  // Show confirmation dialog for airport checkout
  void _showCheckoutConfirmation(BuildContext context, String airport) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Checkout Confirmation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You have selected to pick up your items at:'),
            const SizedBox(height: 8),
            Text(
              airport,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your order will be processed and available for pickup at the airport duty-free shop.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog and go back to cart
            },
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: () {
              // Close the confirmation dialog
              Navigator.of(context).pop();
              
              // Show success order dialog
              _showOrderSuccessDialog(context, airport);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C2C2C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Order'),
          ),
        ],
      ),
    );
  }
  
  // Show order success dialog
  void _showOrderSuccessDialog(BuildContext context, String airport) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to dismiss
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Order Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your order has been successfully placed!',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('Pickup Location: $airport'),
            const SizedBox(height: 4),
            const Text('Order ID: #${12345678}'),
            const SizedBox(height: 4),
            Text('Date: ${DateTime.now().toString().split(' ')[0]}'),
            const SizedBox(height: 16),
            const Text(
              'Please show this order confirmation at the airport duty-free counter to collect your items.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the success dialog
              
              // This ensures we are back at the cart view page
              // If we're in a deeper navigation stack, this will ensure we go back to the cart view
              while (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
              
              // Note: If we need to explicitly navigate to the cart view instead of 
              // just popping dialogs, we would need to implement a callback or use a named route
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C2C2C),
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Show airport selection dialog
  void _showAirportSelection(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Pickup Airport'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: airports.map((airport) => 
            ListTile(
              title: Text(airport),
              onTap: () {
                Navigator.of(context).pop();
                _showCheckoutConfirmation(context, airport);
              },
            )
          ).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const categoryKey = 'shopping'; // Use 'shopping' for the service call

    return FutureBuilder<List<Map<String, String>>>(
      // Fetch data from the 'products' table via the service
      future: recommendationService.fetchRecommendations(categoryKey, city: selectedCity),
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
                  'No products found for $selectedCity',
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

        return Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                        icon: const Icon(Icons.airport_shuttle),
                        tooltip: 'Airport Pickup',
                        onPressed: () => _showAirportSelection(context),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    'Browse unique souvenirs and local products from $selectedCity',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ),
                
                Expanded(
                  child: FadeTransition(
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
                        // Use the passed shoppingCardBuilder function
                        return shoppingCardBuilder(context, recommendation, onAddToCart);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
