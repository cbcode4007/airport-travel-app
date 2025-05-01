/*
  Author:      Colin Bond
  File:        auth_gate.dart
  
  Description: This file handles both logging in and signing up to the application, which is crucial to protect
               sensitive information such as users' entered passports. It makes use of Google's Firebase to
               provide a material interface for the page, a robust and free credential storage system, and Google
               account support.
*/

// Imported dependency packages.

// Material app design, or in other words Google standards for UI.
import 'package:flutter/material.dart';

// Firebase suite for seamless authentication.
// Account functionality with email sign in provision.
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
// Adapted user interface login/signup screen which presents many of the possibilities of Firebase.
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
// Google account sign in option.
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';

// Provide the app client ID.
import 'package:airport_travel_app/main.dart';

// Routes to the other screens.
// Passport setup.
import 'passport.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  // Only go through with loading the authentication form if not already logged in, and redirect after it all.
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {

          // The provided page with standard material design and high functionality.
          return SignInScreen(
            // Authentication methods.
            providers: [
              EmailAuthProvider(),
              GoogleProvider(clientId: clientId),
            ],
            // Upon failure to authenticate, capture the error code to inform both developer and user.
            actions: [              
              AuthStateChangeAction<AuthFailed>((context, state) {
                final error = state.exception;
                // Creates a visually striking error message tailored to the situation front and center.
                showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Error'),
                      content: SingleChildScrollView(
                        child: ListBody(
                          children: <Widget>[
                            Text(error.toString()),
                          ],
                        ),
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('OK'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              }),
            ],
            // The rest of the visual appearance of the app.
            // Company logo.
            headerBuilder: (context, constraints, shrinkOffset) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.asset('assets/images/logo.png'),
                ),                
              );
            },
            // Introduction label.
            subtitleBuilder: (context, action) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: action == AuthAction.signIn
                    ? const Text('Welcome to IxIxI Creator Labs Airport Travel App! Please sign in.')
                    : const Text('Welcome to IxIxI Creator Labs Airport Travel App! Please sign up.'),
              );
            },
            // Terms label.
            footerBuilder: (context, action) {
              return const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'By using our system, you agree to our terms and conditions.',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            },
            // Naturally shrink the logo and keep it visible when scrolling down the page.
            sideBuilder: (context, shrinkOffset) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.asset('assets/images/logo.png'),
                ),
              );
            },
          );
        }
        // Once the user passes authentication, navigate to passport setup.
        return const PassportPage();
      },
    );
  }
}