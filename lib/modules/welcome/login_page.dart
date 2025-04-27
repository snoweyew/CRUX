import 'package:flutter/material.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/services/navigation_service.dart';
import '../../shared/services/mock_data_service.dart';
import '../../shared/services/azure_auth_service.dart';
import '../../shared/models/user_model.dart';

class LoginPage extends StatefulWidget {
  final String userRole;
  final AuthService authService;
  final NavigationService navigationService;
  final MockDataService mockDataService;
  final AzureAuthService azureAuthService;

  const LoginPage({
    Key? key,
    required this.userRole,
    required this.authService,
    required this.navigationService,
    required this.mockDataService,
    required this.azureAuthService,
  }) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await widget.authService.signInWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
        widget.userRole,
      );
      
      if (mounted) {
        if (widget.userRole == 'stb_staff') {
          // Navigate to STB dashboard
          widget.navigationService.navigateToReplacement(
            '/stb_dashboard',
            arguments: user,
          );
        } else {
          // Navigate to local guide dashboard
          widget.navigationService.navigateToReplacement(
            '/local_submission',
            arguments: user,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Format Firebase error messages to be more user-friendly
          if (e.toString().contains('user-not-found')) {
            _errorMessage = 'No account found with this email. Please check your email or register.';
          } else if (e.toString().contains('wrong-password')) {
            _errorMessage = 'Incorrect password. Please try again.';
          } else if (e.toString().contains('wrong-role')) {
            _errorMessage = 'This account is not registered as a ${widget.userRole == 'stb_staff' ? 'STB staff' : 'local guide'}.';
          } else if (e.toString().contains('too-many-requests')) {
            _errorMessage = 'Too many failed login attempts. Please try again later.';
          } else if (e.toString().contains('network-request-failed')) {
            _errorMessage = 'Network error. Please check your internet connection.';
          } else {
            _errorMessage = e.toString();
          }
        });
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
    final isSTBStaff = widget.userRole == 'stb_staff';
    final roleTitle = isSTBStaff ? 'STB Staff Login' : 'Local Guide Login';
    final roleDescription = isSTBStaff
        ? 'Login as Sarawak Tourism Board staff'
        : 'Login as a local tour guide';
    final roleIcon = isSTBStaff ? Icons.business : Icons.tour;
    final primaryColor = isSTBStaff ? const Color(0xFF1A5276) : const Color(0xFF27AE60);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(height: 32),
                
                // Header with role icon
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      roleIcon,
                      size: 50,
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Title and description
                Center(
                  child: Text(
                    roleTitle,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    roleDescription,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                
                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_errorMessage != null) const SizedBox(height: 24),
                
                // Login form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Email field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'Enter your email',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: primaryColor, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword 
                                  ? Icons.visibility 
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: primaryColor, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      
                      // Forgot password link
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Forgot password functionality coming soon'),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: primaryColor,
                          ),
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Login button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Register link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account?",
                            style: TextStyle(color: Colors.grey),
                          ),
                          TextButton(
                            onPressed: () {
                              widget.navigationService.navigateTo(
                                '/register',
                                arguments: widget.userRole,
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: primaryColor,
                            ),
                            child: const Text(
                              'Register',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 