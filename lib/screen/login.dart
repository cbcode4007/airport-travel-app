/*
  Author:      Colin Bond
  File:        login.dart
  
  Description: This file provides an authentication page for users who are already registered with the system.
*/

// Imported dependency packages.
// Material app design, or in other words Google standards for UI.
import 'package:flutter/material.dart';
// More advanced tapping areas.
import 'package:flutter/gestures.dart';
// Dynamic advertisement banners.
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';
// Route to other screens.
// Sign up screen.
import 'package:airport_travel_app/screen/signup.dart';
// Passport screen.
import 'package:airport_travel_app/screen/passport.dart';

// This class is the configuration for the state. It holds the values (in this
// case the title) provided by the parent (in this case the App widget) and
// used by the build method of the State. Fields in a Widget subclass are
// always marked "final".
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.title});
  final String title;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

// This class controls all of the logic for the state of this widget.
class _LoginPageState extends State<LoginPage> {
  // Initially empty error message String for later assignment.
  String errorMessage = '';
  // Error messages.
  // The email field is empty.
  String errorMessageEmailEmpty = 'You must enter an email.';
  // The email field is not a valid email.
  String errorMessageEmailFormat = 'Please enter a real email.';
  // The password field is empty.
  String errorMessagePasswordEmpty = 'You must enter a password.';
  // The database could not be consulted for whatever reason.
  String errorMessageNoCall = 'Could not retrieve data from system. Please try again later.';
  // The email or password does not match a retrieved account record.
  String errorMessageNoMatch = 'Your email or password is invalid.';
  // Strings for the Show password button to change to Hide if it is visible and vice versa.
  String passwordVisibleString = 'Show';
  String passwordVisibleStringYes = 'Hide';
  String passwordVisibleStringNo = 'Show';
  // Bool for whether the password is visible or not.
  bool passwordVisible = false;

  // Mock data for testing.
  String mockEmail = 'colin.bond@test.com';
  String mockPassword = 'test';

  // Controller for email text field extraction and clearing.
  final TextEditingController _emailController = TextEditingController();
  // Controller for password text field extraction and clearing.
  final TextEditingController _passwordController = TextEditingController();
  // Regular expression to check correct format against user input email.
  final emailNumberRegExp = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");

  // Declare an ad unit to be displayed in ad widgets and bool to ensure it loads successfully before proceeding.
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  // Load the page.
  @override
  void initState() {
    super.initState();
    MobileAds.instance.initialize();
    loadAd();
  }

  // Initialize an ad unit to be displayed in ad widgets.
  void loadAd() async {
    // Only initialize ads on supported platforms.
    if (Platform.isAndroid || Platform.isIOS) {
      // Use different ad unit IDs depending on Android or otherwise (IoS); both are not real for testing purposes.
      _bannerAd = BannerAd(
        adUnitId: Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2435281174',
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (Ad ad) {
            setState(() {
              _isAdLoaded = true;
            });
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            ad.dispose();
          },
        ),
      )..load();
    }
  }

  void _login (String email, String password) {
    if (email != '') {
      if (emailNumberRegExp.hasMatch(email)) {
        if (password != '') {
          if ((email == mockEmail) && (password == mockPassword)) {
            _passportPage();
          }
          else {
            _emailController.clear();
            _passwordController.clear();
            _spawnPopup(errorMessageNoMatch);
          }         
        }
        else {
          _passwordController.clear();
          _spawnPopup(errorMessagePasswordEmpty);
        }
      }
      else {
        _emailController.clear();
        _spawnPopup(errorMessageEmailFormat);
      }
    }
    else {
      _emailController.clear();
      _spawnPopup(errorMessageEmailEmpty);
    }
  }

  // Creates a visually striking error message tailored to the situation, front and center.
  Future<void> _spawnPopup(String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
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
  }

  void _showOrHidePassword() {
    setState(
      () {
        passwordVisible = !passwordVisible;
      },
    );
    if (passwordVisible) {
      passwordVisibleString = passwordVisibleStringYes;
    }
    else {
      passwordVisibleString = passwordVisibleStringNo;
    }
  }

  void _signupPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SignupPage(title: 'signup'),
      )
    );
  }

  void _passportPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PassportPage(title: 'passport'),
      )
    );
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 75),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100.0),
                        child: Container(
                          height: 125,
                          width: 125,
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/images/logo.png'),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Airport Travel App',
                        style: TextStyle(
                          color: Colors.lightBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 22.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 35),

                      // Email input.
                      const SizedBox(
                        width: 280,                        
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Email',
                            style: TextStyle(color: Colors.lightBlue, fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        width: 280,
                        child: TextField(
                          controller: _emailController,
                          style: const TextStyle(color: Colors.blueGrey, fontSize: 15),
                          cursorColor: Colors.blueGrey[200],
                          decoration: InputDecoration(
                            hintText: 'example@email.com',
                            hintStyle: TextStyle(
                              color: Colors.blueGrey[200], fontSize: 15, fontWeight: FontWeight.normal
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.blueGrey),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.lightBlue),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Password input.
                      const SizedBox(
                        width: 280,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Password',
                            style: TextStyle(color: Colors.lightBlue, fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        width: 280,
                        child: TextField(
                          controller: _passwordController,
                          obscureText: !passwordVisible,
                          style: const TextStyle(color: Colors.blueGrey, fontSize: 15),
                          cursorColor: Colors.blueGrey[200],
                          decoration: InputDecoration(
                            suffixIcon: InkWell(
                              onTap: _showOrHidePassword,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Text(
                                  passwordVisibleString,
                                  style: const TextStyle(color: Colors.lightBlue, fontSize: 15),
                                ),
                              ),
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.blueGrey),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.lightBlue),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),

                      // Log in button.
                      TextButton(
                        onPressed: () {
                          _login(_emailController.text, _passwordController.text);
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.lightBlue,
                          fixedSize: const Size(150, 40),
                        ),
                        child: const Text(
                          'Log in',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Sign up link.
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Don\'t have an account? ',
                              style: TextStyle(color: Colors.blueGrey),
                            ),
                            TextSpan(
                              text: 'Sign up',
                              style: const TextStyle(color: Colors.lightBlue),
                              recognizer: TapGestureRecognizer()..onTap = _signupPage,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // This pins the ad to the bottom of the screen.
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: _isAdLoaded == false
            ? const SizedBox(height: 50)
            : SizedBox(
                height: _bannerAd!.size.height.toDouble(),
                width: _bannerAd!.size.width.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
      ),
    );
  }
}