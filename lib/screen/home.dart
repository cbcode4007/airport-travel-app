/*
  Author:      Colin Bond
  File:        home.dart
  Description: This file provides an initial page for the Airport Travel Application, where users will
               enter a flight number to proceed to the timer, priority interface and details for it, if it exists.
               Contains additional validation to only call the API when absolutely necessary, as uses are limited.
*/

// Imported dependency packages.
// Encode and decode JSON for processing.
import 'dart:convert';
// Route to the next screen.
import 'package:airport_travel_app/screen/timer.dart';
// Translate raw JSON into Flight objects that can be further processed.
import 'package:airport_travel_app/model/flight.dart';
// Material app design, or in other words Google standards for UI.
import 'package:flutter/material.dart';
// Open Sans Font with readability and a modern feel.
import 'package:google_fonts/google_fonts.dart';
// API calls, retrieving crucial information about a specified flight.
import 'package:http/http.dart' as http;

// This class is the configuration for the state. It holds the values (in this
// case the title) provided by the parent (in this case the App widget) and
// used by the build method of the State. Fields in a Widget subclass are
// always marked "final".
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key, required this.title});
  final String title;
  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

// This class controls all of the logic for the state of this widget.
class _WelcomePageState extends State<WelcomePage> {
  // Initially empty error message String for later assignment.
  String errorMessage = '';
  // Controller for flight IATA text field extraction and clearing.
  final TextEditingController _controller = TextEditingController();
  // Regular expression to check correct format against user input flight IATA.
  final flightNumberRegExp = RegExp(r'^[a-zA-Z]{2,3}\d{1,4}$');

  // Load the page.
  @override
  void initState() {
    super.initState();
  }

  // Calls the AviationStack API and returns a Flight object from JSON that matches the key value (IATA) given.
  Future<Flight?> _callFlightAPI(String iata) async {
    // API Credentials.
    const key = 'c1a9697f9b6263fffcb12a94543e68fa';
    // Link to the request.
    String url = 'https://api.aviationstack.com/v1/flights?access_key=$key&flight_iata=$iata';
    // Pass a unique resource identifier object.
    final uri = Uri.parse(url);
    final response = await http.get(uri);
    // The request was successfully read and responded to.
    if (response.statusCode == 200) {
      final body = response.body;
      final json = jsonDecode(body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>;
      // What was returned is not an empty string, and should therefore be something in the API.
      if (data.isNotEmpty) {
        // Return only focused, important fields for this use case, incorporating them into the Flight model.
        return Flight.fromJson(data.first);
      } else {
        return null;
      }
    } else {
      throw Exception('Failed to fetch flights. Status: ${response.statusCode}');
    }
  }

  // Validates the flight IATA a user enters.
  // First, it will see if anything was entered at all and relay a unique message for them to do so if not.
  // Then, it compares what the user entered to the RegEx which represents correct formatting.
  // When all of that is verified, it will only now call the API to try and find the flight IATA in there.
  // Finally, once it does find a flight IATA in the API, it will proceed to the next page with that flight's data.
  void _validateFlightInput (String flightNumber) async {
    const String errorMessageEmpty = 'You must enter a flight number to continue!';
    const String errorMessageFormat = 'The flight number you entered is invalid! Please use two or three letters at the front and one to four numbers behind them.';
    const String errorMessageCall = 'The flight number you entered could not be found! Please check and try again.';

    // Was anything entered in the text field?
    if (flightNumber != '') {
      // Does the entry adhere to standard IATA formatting?
      if ((flightNumber.length >= 3 && flightNumber.length <= 7) && (flightNumberRegExp.hasMatch(flightNumber))) {
        // See if the IATA is in the system after it at least looks like it could be.
        try {
          final matchedFlight = await _callFlightAPI(flightNumber);
          // Ensure that the widget is still in the widget tree before calling any methods that might change state.
          if (!mounted) return;
          // Take a returned Flight whose IATA matches the entry and navigate to next page with it as a parameter.
          if (matchedFlight != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TimerPage(title: 'timer', flight: matchedFlight,),
              )
            );
          }
          else {
            errorMessage = errorMessageCall;
            _spawnErrorMessage(errorMessage, 100);
          } 

        } 
        catch (e) {
           throw Exception(e);
        }
      }
      else {
        errorMessage = errorMessageFormat;
        _spawnErrorMessage(errorMessage, 150);
      }
    }
    else {
      errorMessage = errorMessageEmpty;
      _spawnErrorMessage(errorMessage, 100);
    }
  }

  // Creates a visually striking error message tailored to the situation at the bottom of the screen.
  void _spawnErrorMessage (String error, double height) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.all(8),
          height: height,
          decoration: const BoxDecoration(
            color: Color(0xFFC72C41),
            borderRadius: BorderRadius.all(Radius.circular(20))
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "An error has occurred!",
                style: TextStyle(fontSize: 17, color: Colors.white)
              ),
              // Dynamic error display that changes depending on what went wrong.
              Text(
                error,
                style: const TextStyle(fontSize: 11, color: Colors.white)
              ),
            ],
          ),
        )
      )
    );
  }

  // Visual appearance of the app.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue,
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

              const SizedBox(height: 16),

              // Welcome heading.
              Text(
                'Welcome!',
                style: GoogleFonts.openSans(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 27,
                ),
              ),

              const SizedBox(height: 24),

              // Instructions body text.
              Column(
                children: [
                  Text(
                    'Please enter your',
                    style: GoogleFonts.openSans(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'IATA flight number below.',
                    style: GoogleFonts.openSans(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Flight IATA input bar with an initial example.
              SizedBox(
                width: 280,
                child: TextField(
                  controller: _controller,
                  style: GoogleFonts.openSans(color: Colors.white, fontSize: 15),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    hintText: 'AAA####',
                    hintStyle: GoogleFonts.openSans(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Submit flight IATA entry button.
              TextButton(
                onPressed: () {
                  _validateFlightInput(_controller.text);
                  _controller.clear();
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  fixedSize: const Size(150, 40),
                ),
                child: Text(
                  'SUBMIT',
                  style: GoogleFonts.openSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.lightBlue,
                  ),
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