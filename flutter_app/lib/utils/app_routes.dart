import 'package:flutter/material.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String pointDetails = '/point-details';
  static const String queue = '/queue';
  static const String profile = '/profile';
  static const String createPoint = '/create-point';
  static const String qrScanner = '/qr-scanner';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );
      
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );
      
      case home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );
      
      // Add other routes as needed
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Route not found'),
            ),
          ),
        );
    }
  }
}

// Import statements (would be at the top in real file)
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => Container();
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) => Container();
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Container();
}