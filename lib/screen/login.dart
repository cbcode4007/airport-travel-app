/*
  Author:      Colin Bond
  File:        login.dart
  
  Description: This file provides an authentication page for users who are already registered with the system.
*/

// Imported dependency packages.
import 'package:flutter/gestures.dart';
// Material app design, or in other words Google standards for UI.
import 'package:flutter/material.dart';
// Route to other screens.
// Sign up.
import 'package:airport_travel_app/screen/signup.dart';
// Passport upload.
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
  String passwordVisibleString = '';
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

  // Load the page.
  @override
  void initState() {
    super.initState();
  }

  void _login (String email, String password) {
    if (email != '') {
      if (emailNumberRegExp.hasMatch(email)) {
        if (password != '') {
          if ((email == mockEmail) && (password == mockPassword)) {
            _spawnErrorMessage('Success!');
            _passportPage();
          }
          else {
            _emailController.clear();
            _passwordController.clear();
            _spawnErrorMessage(errorMessageNoMatch);
          }         
        }
        else {
          _passwordController.clear();
          _spawnErrorMessage(errorMessagePasswordEmpty);
        }
      }
      else {
        _emailController.clear();
        _spawnErrorMessage(errorMessageEmailFormat);
      }
    }
    else {
      _emailController.clear();
      _spawnErrorMessage(errorMessageEmailEmpty);
    }
  }

  // Creates a visually striking error message tailored to the situation at the bottom of the screen.
  Future<void> _spawnErrorMessage(String error) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(error),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: ButtonStyle(overlayColor: WidgetStatePropertyAll<Color?>(Colors.blue[100])),
              child: const Text('OK', style: TextStyle(color: Colors.lightBlue)),
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
    // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => PassportPage(title: 'passport'),
      //   )
      // );
  }

  // Visual appearance of the app.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo area.
              ClipRRect(
                borderRadius: BorderRadius.circular(100.0),
                child: Container(
                  height: 100,
                  width: 100,
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    image: DecorationImage(
                      image: AssetImage('assets/images/logo.png'),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // Welcome heading.
              const Text(
                'Log in to Airport Travel App',
                style: TextStyle(
                  color: Colors.lightBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 27,
                ),
              ),

              const SizedBox(height: 50),

              // Email.
              // Email label.
              const SizedBox(
                width: 280,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Email',
                      style: TextStyle(
                        color: Colors.lightBlue,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              // Email input.
              SizedBox(
                width: 280,
                child: TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 15, fontWeight: FontWeight.normal),
                  cursorColor: Colors.blueGrey[200],
                  decoration: InputDecoration(
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueGrey),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.lightBlue),
                    ),                    
                    hintText: 'example@example.example',
                    hintStyle: TextStyle(
                      color: Colors.blueGrey[200],
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              // Password.
              // Password label.
              const SizedBox(
                width: 280,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Password',
                      style: TextStyle(
                        color: Colors.lightBlue,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5), 
              // Password input.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 280,
                    child: TextField(
                      controller: _passwordController,
                      obscureText: !passwordVisible,
                      style: const TextStyle(color: Colors.blueGrey, fontSize: 15),
                      cursorColor: Colors.blueGrey[200],
                      decoration: InputDecoration(
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueGrey),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.lightBlue),
                        ),
                        suffix: GestureDetector(
                          onTap: _showOrHidePassword,
                          child: Text(
                            passwordVisibleString,
                            style: const TextStyle(color: Colors.lightBlue, fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

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
              const SizedBox(height: 16),
              // Sign up redirect link.
              
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
                      recognizer: TapGestureRecognizer()
                        ..onTap = () { _signupPage();
                      },
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}