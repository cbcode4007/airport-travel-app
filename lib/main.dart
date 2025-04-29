/*
  Author:      Colin Bond
  File:        main.dart
  
  Description: This file is at the center of the Airport Travel Application, being responsible for
               running it and navigating to its home page.
*/

// Imported dependency packages.
// Material app design, or in other words Google standards for UI.
import 'package:airport_travel_app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
// Timezone logic for correct displays.
import 'package:timezone/data/latest.dart' as tz;
// Route to the next screen.
// import 'package:airport_travel_app/screen/login.dart';
import 'package:airport_travel_app/screen/auth_gate.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// const clientId = '299611344278-kq29k1540bnkr9v5vchnml3ub35d7bcs.apps.googleusercontent.com';

void main () async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  tz.initializeTimeZones();
  MobileAds.instance.initialize();

  runApp(const AirportTravelApp());
}

class AirportTravelApp extends StatelessWidget {
  const AirportTravelApp({super.key});

  // This widget is the root of the application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Navigate to the first or Welcome page.
      // home: const LoginPage(),
      home: const AuthGate(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue)
      ),
    );
  }
}