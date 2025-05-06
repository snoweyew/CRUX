import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../shared/models/user_model.dart';

class CartItemInputPage extends StatefulWidget {
  final UserModel user;
  
  const CartItemInputPage({Key? key, required this.user}) : super(key: key);

  @override
  State<CartItemInputPage> createState() => _CartItemInputPageState();
}

class _CartItemInputPageState extends State<CartItemInputPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  
  String _selectedCategory = 'souvenir';
  String _selectedCity = '';
  bool _isSubmitting = false;
  final _supabase = Supabase.instance.client;
  
  // Sample images for quick selection
  final List<String> _sampleImages = [
    'https://images.unsplash.com/photo-1604933762023-7213af7ff7a7?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60', // Black pepper
    'https://images.unsplash.com/photo-1602173574767-37ac01994b2a?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60', // Handicraft
    'https://images.unsplash.com/photo-1548943487-a2e4e43b4853?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60', // Food
    'https://images.unsplash.com/photo-1601024445121-e5b82f020549?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60', // Art
    'https://images.unsplash.com/photo-1513885535751-8b9238bd345a?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60', // Local products
  ];
  
  // Sample product data for quick filling
  final List<Map<String, String>> _sampleProducts = [
    {
      'name': 'Sarawak Laksa Paste',
      'description': 'Authentic Sarawak laksa paste, perfect for making the famous Sarawak laksa soup at home.',
      'price': '18.90',
      'location': 'Kuching Central Market',
      'category': 'food_product',
      'city': 'Kuching',
    },
    {
      'name': 'Kek Lapis (Layer Cake)',
      'description': 'Traditional colorful layered cake, a Sarawak specialty with intricate patterns and rich flavor.',
      'price': '45.00',
      'location': 'Miri Cake House',
      'category': 'food_product',
      'city': 'Miri',
    },
    {
      'name': 'Pua Kumbu Tote Bag',
      'description': 'Handcrafted tote bag made from traditional Iban textile with ancient motifs and patterns.',
      'price': '89.90',
      'location': 'Sibu Heritage Center',
      'category': 'handicraft',
      'city': 'Sibu',
    },
    {
      'name': 'Wooden Orang Utan Carving',
      'description': 'Hand-carved wooden figurine of Sarawak\'s iconic orangutan, made by local artisans.',
      'price': '65.00',
      'location': 'Kuching Craft Market',
      'category': 'handicraft',
      'city': 'Kuching',
    },
    {
      'name': 'Sarawak White Pepper',
      'description': 'Premium grade white pepper from Sarawak\'s fertile lands, known for its unique aroma.',
      'price': '22.50',
      'location': 'Bintulu Farmers Market',
      'category': 'food_product',
      'city': 'Bintulu',
    },
  ];
  
  @override
  void initState() {
    super.initState();
    
    // Define valid cities
    final validCities = ['Kuching', 'Miri', 'Sibu', 'Bintulu'];
    
    // Ensure selected city is valid
    if (widget.user.selectedCity != null && validCities.contains(widget.user.selectedCity)) {
      _selectedCity = widget.user.selectedCity!;
    } else {
      _selectedCity = 'Kuching'; // Default to Kuching if user's city is invalid
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }
  
  void _fillWithSampleProduct(Map<String, String> sample) {
    setState(() {
      _nameController.text = sample['name'] ?? '';
      _descriptionController.text = sample['description'] ?? '';
      _locationController.text = sample['location'] ?? '';
      _priceController.text = sample['price'] ?? '';
      _selectedCategory = sample['category'] ?? 'souvenir';
      _selectedCity = sample['city'] ?? 'Kuching';
      
      // Assign a random sample image
      final random = DateTime.now().millisecondsSinceEpoch % _sampleImages.length;
      _imageUrlController.text = _sampleImages[random];
    });
  }
  
  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSubmitting = true;
    });
    
    final productData = {
      'id': const Uuid().v4(), // Generate unique ID
      'name': _nameController.text,
      'description': _descriptionController.text,
      'location': _locationController.text,
      'price': double.parse(_priceController.text),
      'image_url': _imageUrlController.text,
      'category': _selectedCategory,
      'city': _selectedCity,
      'created_at': DateTime.now().toIso8601String(),
    };
    
    try {
      await _supabase.from('products').insert(productData);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Product added successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
      
      // Clear form or navigate back
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final cities = ['Kuching', 'Miri', 'Sibu', 'Bintulu'];
    final categories = [
      {'value': 'souvenir', 'label': 'Souvenir'},
      {'value': 'food_product', 'label': 'Food Product'},
      {'value': 'handicraft', 'label': 'Handicraft'},
      {'value': 'clothing', 'label': 'Clothing'},
      {'value': 'accessory', 'label': 'Accessory'},
    ];
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Product'),
        backgroundColor: const Color(0xFF2C2C2C),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Quick fill buttons
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Fill with Sample Data:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: _sampleProducts.map((sample) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ElevatedButton(
                                  onPressed: () => _fillWithSampleProduct(sample),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2C2C2C),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text(sample['name']!.split(' ')[0]),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Main form
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a product name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location/Vendor',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a location';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price (RM)',
                    border: OutlineInputBorder(),
                    prefixText: 'RM ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a price';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    border: OutlineInputBorder(),
                    hintText: 'https://example.com/image.jpg',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an image URL';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Sample images
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Select Images:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _sampleImages.length,
                            itemBuilder: (context, index) {
                              final imageUrl = _sampleImages[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _imageUrlController.text = imageUrl;
                                    });
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      imageUrl,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const SizedBox(
                                        width: 100,
                                        height: 100,
                                        child: Icon(Icons.broken_image),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Category dropdown
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedCategory,
                  items: categories.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat['value'],
                      child: Text(cat['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // City dropdown
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'City',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedCity,
                  items: cities.map((city) {
                    return DropdownMenuItem<String>(
                      value: city,
                      child: Text(city),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCity = value!;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a city';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // Submit button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C2C2C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Submitting...'),
                          ],
                        )
                      : const Text('Add Product'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}