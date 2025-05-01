/*
  Author:      Colin Bond
  File:        main.dart
  
  Description: This file is at the center of the Airport Travel Application, being responsible for
               running it and initially navigating to a specific page after checking a session exists.
*/

// Imported dependency packages.

// Material app design, or in other words Google standards for UI.
import 'package:flutter/material.dart';

// Firebase suite for seamless authentication.
// Configuration.
import 'package:airport_travel_app/firebase_options.dart';
// Account functionality.
import 'package:firebase_auth/firebase_auth.dart';
// Database storage functionality.
import 'package:firebase_core/firebase_core.dart';

// Timezone logic for correct displays initialization.
import 'package:timezone/data/latest.dart' as tz;

// Routes to the possible initial screens.
// Authentication gate.
import 'package:airport_travel_app/screen/auth_gate.dart';
// Passport setup.
import 'package:airport_travel_app/screen/passport.dart';


// Central Firebase client ID to pass into the authentication gate for verification on the app side.
const clientId = '299611344278-kq29k1540bnkr9v5vchnml3ub35d7bcs.apps.googleusercontent.com';

// Initialize authentication, timezone and advertisement databases before running the app so they can load.
void main () async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  tz.initializeTimeZones();
  runApp(const AirportTravelApp());
}

class AirportTravelApp extends StatelessWidget {
  const AirportTravelApp({super.key});

  // This widget is the root of the application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue)
      ),
      // Dynamically loaded page that listens to state changes of Firebase authentication.
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Loading screen.
            return const Center(child: CircularProgressIndicator());
          } 
          // When the user restarts the app, open a different page depending on their last login status.         
          if (snapshot.hasData) {
            // Redirect to the first page in the information setup process for a logged in user.
            return const PassportPage();
          } else {
            // Go to the real first page requiring account credentials for a signed off user.
            return const AuthGate();
          }
        },
      ),
    );
  }
}