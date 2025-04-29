import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<ProfileScreen>(
                  builder:
                      (context) => ProfileScreen(
                        appBar: AppBar(title: const Text('User Profile')),
                        actions: [
                          SignedOutAction((context) {
                            Navigator.of(context).pop();
                          }),
                        ],
                        children: [
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.all(2),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: Image.asset('assets/images/logo.png'),
                            ),
                          ),
                        ],
                      ),
                ),
              );
            },
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          children: [
            // Image.asset('assets/images/logo.png'),
            // Text('Welcome!', style: Theme.of(context).textTheme.displaySmall),
            // const SignOutButton(),

            IconButton(
              icon: const Icon(Icons.logout),
              iconSize: 50,
              tooltip: 'Sign Out',
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.signOut();
                  // Navigate to login screen or do something else
                } catch (e) {
                  print('Sign out error: $e');
                }
              },
            )

          ],
        ),
      ),
    );
  }
}