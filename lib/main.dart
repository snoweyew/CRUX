import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app_router.dart';
import 'shared/services/auth_service.dart';
import 'shared/services/navigation_service.dart';
import 'shared/services/mock_data_service.dart';
import 'shared/services/azure_auth_service.dart';
import 'shared/config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Show loading screen while initializing
  runApp(
    MaterialApp(
      home: AppLoader(),
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
    ),
  );
}

class AppLoader extends StatefulWidget {
  const AppLoader({super.key});

  @override
  _AppLoaderState createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Load environment variables
      await dotenv.load(fileName: '.env');
      
      // Initialize Firebase
      await Firebase.initializeApp();
      print('Firebase initialized successfully');

      // If everything succeeds, launch main app
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MyApp(
              authService: AuthService(),
              navigationService: NavigationService(),
              mockDataService: MockDataService(),
              azureAuthService: AzureAuthService(
                baseUrl: AppConfig.apiUrl,
                apiKey: AppConfig.apiKey,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error initializing app: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 120,
                height: 120,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.image,
                  size: 120,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Initializing app...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Failed to initialize app',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _initializeApp();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final NavigationService navigationService;
  final MockDataService mockDataService;
  final AzureAuthService azureAuthService;

  const MyApp({
    super.key,
    required this.authService,
    required this.navigationService,
    required this.mockDataService,
    required this.azureAuthService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sarawak Travel App',
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      navigatorKey: navigationService.navigatorKey,
      onGenerateRoute:
          AppRouter(
            authService: authService,
            navigationService: navigationService,
            mockDataService: mockDataService,
            azureAuthService: azureAuthService,
          ).onGenerateRoute,
      initialRoute: '/',
    );
  }
}
