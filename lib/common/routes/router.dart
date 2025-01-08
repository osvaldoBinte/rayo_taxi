import 'package:flutter/material.dart';
import 'package:rayo_taxi/common/app/splash_screen.dart';
import 'package:rayo_taxi/common/settings/routes_names.dart';
import 'package:rayo_taxi/features/client/presentation/pages/home_page/home_page.dart';
import 'package:rayo_taxi/features/travel/presentation/page/acceptTravel/accept_travel_page.dart';

class RouterApp {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RoutesNames.homePage:
        final args = settings.arguments as Map<String, dynamic>?;
        final selectedIndex = args?['selectedIndex'] ?? 0;
        return MaterialPageRoute(
          builder: (_) => HomePage(selectedIndex: selectedIndex),
        );

     
      case RoutesNames.welcomePage:
      return MaterialPageRoute(
          builder: (_) => SplashScreen(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Ruta no encontrada: ${settings.name}'),
            ),
          ),
        );
    }
  }
}
