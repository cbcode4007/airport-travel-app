import 'package:flutter/material.dart';
import 'package:airport_travel_app/screen/home.dart';

void main() {
  runApp(const AirportTravelApp());
}

class AirportTravelApp extends StatelessWidget {
  const AirportTravelApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        // This is the theme of the homepage.
      ),
      home: const WelcomePage(title: 'home'),
    );
  }
}
