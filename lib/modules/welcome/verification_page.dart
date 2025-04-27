import 'package:flutter/material.dart';
import 'dart:io';
import '../../shared/models/user_model.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/services/navigation_service.dart';
import '../../shared/services/mock_data_service.dart';

class VerificationPage extends StatefulWidget {
  final UserModel user;
  final AuthService authService;
  final NavigationService navigationService;
  final MockDataService mockDataService;

  const VerificationPage({
    Key? key,
    required this.user,
    required this.authService,
    required this.navigationService,
    required this.mockDataService,
  }) : super(key: key);

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  File? _passportImage;
  File? _selfieImage;
  bool _isVerifying = false;
  bool _passportUploaded = false;
  bool _selfieUploaded = false;
  
  // For demo purposes, we'll simulate image selection
  void _selectPassportImage() {
    // In a real app, this would use image_picker to get an image from gallery or camera
    setState(() {
      _passportUploaded = true;
    });
  }
  
  void _selectSelfieImage() {
    // In a real app, this would use image_picker to get an image from camera
    setState(() {
      _selfieUploaded = true;
    });
  }
  
  void _verifyIdentity() async {
    setState(() {
      _isVerifying = true;
    });
    
    try {
      // Simulate verification process
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        // Navigate to itinerary personalization page
        widget.navigationService.navigateToReplacement(
          '/itinerary_personalization',
          arguments: widget.user,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: ${e.toString()}')),
        );
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Identity Verification'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Verify Your Identity',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'To ensure the security of our users, we need to verify your identity before you can proceed.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            
            // Passport upload section
            _buildVerificationSection(
              title: 'Passport or ID Card',
              description: 'Upload a clear photo of your passport or ID card',
              icon: Icons.credit_card,
              isUploaded: _passportUploaded,
              onUpload: _selectPassportImage,
            ),
            const SizedBox(height: 24),
            
            // Selfie upload section
            _buildVerificationSection(
              title: 'Selfie Verification',
              description: 'Take a selfie to verify it\'s really you',
              icon: Icons.face,
              isUploaded: _selfieUploaded,
              onUpload: _selectSelfieImage,
            ),
            const SizedBox(height: 40),
            
            // Privacy notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.shade200,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.privacy_tip,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Privacy Notice',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your documents are securely encrypted and will only be used for verification purposes. We do not store your actual documents after verification is complete.',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Verify button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_passportUploaded && _selfieUploaded && !_isVerifying)
                    ? _verifyIdentity
                    : null,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isVerifying
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Verify Identity',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Skip for now button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: TextButton(
                onPressed: () {
                  // Navigate to itinerary personalization page
                  widget.navigationService.navigateToReplacement(
                    '/itinerary_personalization',
                    arguments: widget.user,
                  );
                },
                child: const Text(
                  'Skip for Now',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVerificationSection({
    required String title,
    required String description,
    required IconData icon,
    required bool isUploaded,
    required VoidCallback onUpload,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUploaded ? Colors.green.shade100 : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isUploaded ? Colors.green : Colors.grey.shade700,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isUploaded)
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 24,
                ),
            ],
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: onUpload,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isUploaded ? Colors.green : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: isUploaded
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Uploaded Successfully',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.upload_file,
                            color: Colors.grey.shade500,
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to Upload',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
} 