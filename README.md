<<<<<<< HEAD
# Sarawak Travel App

A Flutter application for personalized travel itineraries in Sarawak, Malaysia.

## Features

- User role selection (Tourist, Local Resident, Sarawak Tourism Board)
- City selection via slider
- Customizable itinerary preferences:
  - Food experiences (0-5 per day)
  - Attractions (0-3 per day)
  - Cultural experiences (0-2 per day)
  - Trip duration (1-3 days)
- Itinerary generation based on preferences
- Detailed day-by-day itinerary view

## Project Structure

```
lib/
├── main.dart                                  # App entry point
├── app_router.dart                            # Navigation routing
├── modules/
│   ├── welcome/
│   │   ├── welcome_page.dart                  # Welcome page with login and city selection
│   │   └── user_role.dart                     # User role definitions
│   ├── itinerary_personalization/
│   │   ├── itinerary_personalization_page.dart # Itinerary customization UI
│   │   ├── itinerary_customizer.dart          # Itinerary customization logic
│   │   ├── itinerary_generator.dart           # Itinerary generation service
│   │   └── itinerary_model.dart               # Itinerary data models
├── shared/
│   ├── models/
│   │   ├── user_model.dart                    # User data model
│   │   └── preference_model.dart              # Preference data model
│   ├── services/
│   │   ├── auth_service.dart                  # Authentication service
│   │   ├── navigation_service.dart            # Navigation service
│   │   └── mock_data_service.dart             # Mock data provider
```

## Getting Started

### Prerequisites

- Flutter SDK (2.10.0 or higher)
- Dart SDK (2.16.0 or higher)
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/sarawak_travel_app.git
   ```

2. Navigate to the project directory:
   ```
   cd sarawak_travel_app
   ```

3. Get dependencies:
   ```
   flutter pub get
   ```

4. Run the app:
   ```
   flutter run
   ```

## Development Notes

This app uses a mock data service to simulate backend API calls. In a production environment, these would be replaced with actual API calls to a backend service.

## Future Enhancements

- User authentication with Firebase
- Real-time itinerary updates
- Social sharing features
- Offline mode support
- Integration with maps and navigation
- Booking functionality for activities and accommodations

## License

This project is licensed under the MIT License - see the LICENSE file for details.
=======
# CRUX
>>>>>>> main
