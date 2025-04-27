class CartItem {
  final String productId;
  final String name;
  final String location;
  final double price;
  final int quantity;
  final String? imageUrl; // Added imageUrl

  CartItem({
    required this.productId,
    required this.name,
    required this.location,
    required this.price,
    required this.quantity,
    this.imageUrl, // Added imageUrl
  });
}