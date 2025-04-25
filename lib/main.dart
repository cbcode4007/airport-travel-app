/*
  Author:      Colin Bond
  File:        main.dart
  
  Description: This file is at the center of the Airport Travel Application, being responsible for
               running it and navigating to its home page.
*/

// Imported dependency packages.
// Material app design, or in other words Google standards for UI.
import 'package:flutter/material.dart';
// Route to the next screen.
import 'package:airport_travel_app/screen/login.dart';

void main() {
  runApp(const AirportTravelApp());
}

class AirportTravelApp extends StatelessWidget {
  const AirportTravelApp({super.key});

  // This widget is the root of the application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Navigate to the first or Welcome page.
      home: const LoginPage(title: 'login'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue)
      ),
    );
  }
}