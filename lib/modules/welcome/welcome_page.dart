import 'package:flutter/material.dart';
import 'dart:math';
import '../../shared/services/auth_service.dart';
import '../../shared/services/navigation_service.dart';
import '../../shared/services/mock_data_service.dart';
import '../../shared/models/user_model.dart';

class WelcomePage extends StatefulWidget {
  final AuthService authService;
  final NavigationService navigationService;
  final MockDataService mockDataService;

  const WelcomePage({
    Key? key,
    required this.authService,
    required this.navigationService,
    required this.mockDataService,
  }) : super(key: key);

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with SingleTickerProviderStateMixin {
  // Animation controller for the slide-up button
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  
  // Drag offset for manual animations
  double _dragOffset = 0.0;
  
  // Background image URL
  final String backgroundImageUrl = 'https://images.pexels.com/photos/7000965/pexels-photo-7000965.jpeg';
  
  // Login dialog visibility
  bool _showLoginOptions = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    // Create slide animation for the bottom bar
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    // Start the animation after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      _animationController.forward();
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  // Navigate to the city selection page as tourist
  void _proceedAsTourist() {
    // Create a user with tourist role
    final user = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Tourist',
      role: 'tourist',
      selectedCity: '',
    );
    
    widget.navigationService.navigateTo('/city_selection', arguments: user);
  }
  
  // Show staff login options dialog
  void _showStaffLoginOptions() {
    setState(() {
      _showLoginOptions = true;
    });
  }
  
  // Handle STB login
  void _handleSTBLogin() async {
    // Navigate to login page with STB staff role
    widget.navigationService.navigateTo('/login', arguments: 'stb_staff');
    
    // Close the dialog
    setState(() {
      _showLoginOptions = false;
    });
  }
  
  // Handle local login
  void _handleLocalLogin() async {
    // Navigate to login page with local guide role
    widget.navigationService.navigateTo('/login', arguments: 'local_guide');
    
    // Close the dialog
    setState(() {
      _showLoginOptions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Main content
          GestureDetector(
            onVerticalDragUpdate: (details) {
              // Update drag offset based on drag movement
              setState(() {
                _dragOffset -= details.primaryDelta! / 100;
                // Clamp the value between 0 and 1
                _dragOffset = _dragOffset.clamp(0.0, 1.0);
              });
              
              // If user swipes up significantly, navigate as tourist
              if (details.primaryDelta != null && details.primaryDelta! < -20 && _dragOffset > 0.5) {
                _proceedAsTourist();
              }
            },
            onVerticalDragEnd: (details) {
              // Reset drag offset when drag ends without navigation
              if (_dragOffset < 0.5) {
                setState(() {
                  _dragOffset = 0.0;
                });
              }
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image
                Image.network(
                  backgroundImageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[800],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / 
                                  (loadingProgress.expectedTotalBytes ?? 1)
                              : null,
                          color: const Color(0xFFFBE583),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => 
                    Container(
                      color: Colors.grey[800],
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.image_not_supported, color: Colors.white70, size: 50),
                            const SizedBox(height: 16),
                            Text(
                              'Could not load image',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                ),
                
                // Gradient overlays for better text readability (adapted from city_selection_page)
                Stack(
                  children: [
                    // Overlay gradient at the top
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 200,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Overlay gradient at the bottom
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 400,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.9),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Content
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row with combined flag and user icon
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Combined clickable area for flag and user icon
                            GestureDetector(
                              onTap: _showStaffLoginOptions, // Single tap target
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Adjust padding as needed
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row( // Keep icons side-by-side
                                  mainAxisSize: MainAxisSize.min, // Fit content
                                  children: [
                                    // Sarawak flag icon (no GestureDetector needed here)
                                    Container(
                                      width: 40,
                                      height: 25,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: CustomPaint(
                                        size: Size(40, 25),
                                        painter: SarawakFlagPainter(),
                                      ),
                                    ),
                                    const SizedBox(width: 12), // Space between icons
                                    // User Icon (no GestureDetector needed here)
                                    const Icon(
                                      Icons.person_outline, // User icon
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Empty space to maintain layout (or remove if not needed)
                            const SizedBox(), 
                          ],
                        ),
                        
                        const Spacer(flex: 3),
                        
                        // Title text - Explore.
                        const Text(
                          'Explore.',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        
                        // Title text - Travel.
                        const Text(
                          'Travel.',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        
                        // Title text - Inspire.
                        const Text(
                          'Inspire.',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Subtitle
                        const Text(
                          'Life is all about journey.\nFind yours.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ),
                        
                        const Spacer(flex: 2),
                        
                        // Bottom section with arrow and text
                        SlideTransition(
                          position: _slideAnimation,
                          child: Transform.translate(
                            offset: Offset(0, -15 * _dragOffset),
                            child: Center(
                              child: Column(
                                children: [
                                  // Upward arrow indicator with animation
                                  _buildUpwardArrow(),
                                  const SizedBox(height: 16),
                                  // Tourist text
                                  const Text(
                                    'I am a Tourist',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  // Invisible button for tapping
                                  GestureDetector(
                                    onTap: _proceedAsTourist,
                                    child: Container(
                                      width: double.infinity,
                                      height: 60,
                                      color: Colors.transparent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Staff login options overlay
          if (_showLoginOptions)
            _buildStaffLoginOptionsOverlay(),
        ],
      ),
    );
  }
  
  // Build the upward pointing arrow
  Widget _buildUpwardArrow() {
    return Column(
      children: [
        Icon(
          Icons.keyboard_arrow_up,
          color: Colors.white,
          size: 30,
        ),
        const SizedBox(height: 4),
        Icon(
          Icons.keyboard_arrow_up,
          color: Colors.white,
          size: 30,
        ),
      ],
    );
  }
  
  // Build staff login options overlay
  Widget _buildStaffLoginOptionsOverlay() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showLoginOptions = false;
        });
      },
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Staff Login',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select your login type',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                
                // STB Staff option
                _buildLoginOptionButton(
                  icon: Icons.business,
                  title: 'STB Staff',
                  subtitle: 'Login as Sarawak Tourism Board staff',
                  onTap: _handleSTBLogin,
                ),
                
                const SizedBox(height: 16),
                
                // Local Guide option
                _buildLoginOptionButton(
                  icon: Icons.tour,
                  title: 'Sarawakian',
                  subtitle: 'Login as a local tour guide',
                  onTap: _handleLocalLogin,
                ),
                
                const SizedBox(height: 24),
                
                // Cancel button
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showLoginOptions = false;
                    });
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
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
  
  // Build login option button
  Widget _buildLoginOptionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.grey.shade700,
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
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade700,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter for Sarawak flag
class SarawakFlagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    
    // Paint for black triangle (top half)
    final blackPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    
    // Paint for red triangle (bottom half)
    final redPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    
    // Create path for black triangle (top half)
    final blackPath = Path()
      ..moveTo(0, 0)
      ..lineTo(width, 0)
      ..lineTo(0, height)
      ..close();
    
    // Create path for red triangle (bottom half)
    final redPath = Path()
      ..moveTo(width, 0)
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();
    
    // Draw the triangles
    canvas.drawPath(blackPath, blackPaint);
    canvas.drawPath(redPath, redPaint);
    
    // Draw the nine-pointed star
    final centerX = width / 2;
    final centerY = height / 2;
    final radius = height / 3;
    
    final starPaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.fill;
    
    // Draw a 9-pointed star
    final starPath = Path();
    final outerRadius = radius;
    final innerRadius = radius * 0.4;
    final totalPoints = 9;
    
    for (int i = 0; i < totalPoints * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = i * pi / totalPoints;
      final x = centerX + radius * cos(angle - pi / 2);
      final y = centerY + radius * sin(angle - pi / 2);
      
      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
    }
    starPath.close();
    
    canvas.drawPath(starPath, starPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}