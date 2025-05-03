import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'app_router.dart';
import 'shared/services/auth_service.dart';
import 'shared/services/navigation_service.dart';
import 'shared/services/mock_data_service.dart';
import 'shared/config/app_config.dart';
import 'config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure logging
  _setupLogging();
  final logger = Logger('Main');
  logger.info('Starting Sarawak Travel App');
  
  // Show loading screen while initializing
  runApp(
    MaterialApp(
      home: AppLoader(),
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
    ),
  );
}

void _setupLogging() {
  // Only display logs in debug mode
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.message}');
    
    if (record.error != null) {
      // ignore: avoid_print
      print('Error: ${record.error}');
    }
    
    if (record.stackTrace != null) {
      // ignore: avoid_print
      print('Stack trace: ${record.stackTrace}');
    }
  });
}

class AppLoader extends StatefulWidget {
  const AppLoader({super.key});

  @override
  _AppLoaderState createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> {
  final Logger _logger = Logger('AppLoader');
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      _logger.info('Loading environment variables');
      // Load environment variables
      await dotenv.load(fileName: '.env');
      
      _logger.info('Initializing Supabase');
      // Initialize Supabase
      await SupabaseConfig.initialize();
      _logger.info('Supabase initialized successfully');

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
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      _logger.severe('Error initializing app', e, stackTrace);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _getUserFriendlyErrorMessage(e);
        });
      }
    }
  }
  
  String _getUserFriendlyErrorMessage(dynamic error) {
    // Provide user-friendly error messages
    if (error.toString().contains('dotenv')) {
      return 'Failed to load configuration. Please check that the .env file exists and is properly formatted.';
    } else if (error.toString().contains('supabase') || error.toString().contains('Supabase')) {
      return 'Failed to connect to the backend server. Please check your internet connection and try again.';
    } else {
      return 'An unexpected error occurred. Please try again later.\n\nDetails: ${error.toString()}';
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
                  Icons.travel_explore,
                  size: 120,
                  color: Colors.green,
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
  final Logger _logger = Logger('MyApp');

  MyApp({
    super.key,
    required this.authService,
    required this.navigationService,
    required this.mockDataService,
  }) {
    _logger.info('Main app initialized');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sarawak Travel App',
      theme: ThemeData(
        primarySwatch: Colors.green, 
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      navigatorKey: navigationService.navigatorKey,
      onGenerateRoute:
          AppRouter(
            authService: authService,
            navigationService: navigationService,
            mockDataService: mockDataService,
          ).onGenerateRoute,
      initialRoute: '/',
    );
  }
}
