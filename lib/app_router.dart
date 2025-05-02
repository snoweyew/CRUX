import 'package:flutter/material.dart';
import 'modules/welcome/welcome_page.dart';
import 'modules/welcome/city_selection_page.dart';
import 'modules/welcome/visitor_type_selection_page.dart';
import 'modules/welcome/verification_page.dart';
import 'modules/welcome/login_page.dart';
import 'modules/welcome/register_page.dart';
import 'modules/itinerary_personalization/itinerary_personalization_page.dart';
import 'modules/recommendation/recommendation_page.dart';
import 'modules/staff/stb_dashboard_page.dart';
import 'modules/local/local_main_page.dart';
import 'shared/services/auth_service.dart';
import 'shared/services/navigation_service.dart';
import 'shared/services/mock_data_service.dart';
import 'shared/services/azure_auth_service.dart';
import 'shared/services/recommendation_service.dart';
import 'shared/config/app_config.dart';
import 'shared/models/user_model.dart';
import 'shared/services/http_service.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:http/http.dart' as http;
import 'shared/services/supabase_submission_service.dart';

class AppRouter {
  final AuthService authService;
  final NavigationService navigationService;
  final MockDataService mockDataService;
  final AzureAuthService azureAuthService;

  AppRouter({
    required this.authService,
    required this.navigationService,
    required this.mockDataService,
    required this.azureAuthService,
  });

  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => WelcomePage(
            authService: authService,
            navigationService: navigationService,
            mockDataService: mockDataService,
          ),
        );
      case '/login':
        final String userRole = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => LoginPage(
            userRole: userRole,
            authService: authService,
            navigationService: navigationService,
            mockDataService: mockDataService,
            azureAuthService: azureAuthService,
          ),
        );
      case '/register':
        final String userRole = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => RegisterPage(
            userRole: userRole,
            authService: authService,
            navigationService: navigationService,
            mockDataService: mockDataService,
            azureAuthService: azureAuthService,
          ),
        );
      case '/verification':
        final UserModel user = settings.arguments as UserModel;
        return MaterialPageRoute(
          builder: (_) => VerificationPage(
            user: user,
            authService: authService,
            navigationService: navigationService,
            mockDataService: mockDataService,
          ),
        );
      case '/stb_dashboard':
        final UserModel user = settings.arguments as UserModel;
        return MaterialPageRoute(
          builder: (_) => STBDashboardPage(
            user: user,
            submissionService: SupabaseSubmissionService(), // Ensure this is passed
          ),
        );
      case '/local_main': 
        final UserModel user = settings.arguments as UserModel;
        return MaterialPageRoute(
          builder: (_) => LocalMainPage(
            user: user,
            submissionService: SupabaseSubmissionService(),
          ),
        );
      case '/city_selection':
        final UserModel user = settings.arguments as UserModel;
        if (user.role == 'tourist') {
          return MaterialPageRoute(
            builder: (_) => CitySelectionPage(
              authService: authService,
              navigationService: navigationService,
              mockDataService: mockDataService,
              tempUser: user,
            ),
          );
        } else {
          // Redirect non-tourists back to welcome page
          return MaterialPageRoute(
            builder: (_) => WelcomePage(
              authService: authService,
              navigationService: navigationService,
              mockDataService: mockDataService,
            ),
          );
        }
      case '/itinerary_personalization':
        final UserModel user = settings.arguments as UserModel;
        return MaterialPageRoute(
          builder: (_) => ItineraryPersonalizationPage(
            user: user,
            navigationService: navigationService,
            mockDataService: mockDataService,
            httpService: HttpService(baseUrl: AppConfig.apiUrl),
          ),
        );
      case '/recommendation':
        final Map<String, dynamic> args = settings.arguments as Map<String, dynamic>;
        final UserModel user = args['user'] as UserModel;
        final itinerary = args['itinerary']; // Can be null

        // Instantiate RecommendationService here or ensure it's passed if needed globally
        final recommendationService = RecommendationService();

        return MaterialPageRoute(
          builder: (_) => RecommendationPage( // CHANGED to RecommendationPage
            user: user,
            navigationService: navigationService,
            recommendationService: recommendationService, // Pass the service instance
            itinerary: itinerary,
          ),
        );
      case '/visitor_type':
        final UserModel user = settings.arguments as UserModel;
        return MaterialPageRoute(
          builder: (_) => VisitorTypeSelectionPage(
            navigationService: navigationService,
            user: user,
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
