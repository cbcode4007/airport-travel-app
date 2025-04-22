// Encode and decode JSON for processing.
import 'dart:convert';
// Route to the next screen.
import 'package:airport_travel_app/screen/timer.dart';
// Translate raw JSON into Flight objects.
import 'package:airport_travel_app/model/flight.dart';
// Material app design, or in other words Google recommendations for UI.
import 'package:flutter/material.dart';
// Open Sans Font.
import 'package:google_fonts/google_fonts.dart';
// API calls.
import 'package:http/http.dart' as http;
// Window sizing for visualising mobile display, temporary.
import 'package:window_manager/window_manager.dart';

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
  // Controller for flight number text field extraction and clearing.
  final TextEditingController _controller = TextEditingController();
  // Regular expression to check correct format against user input flight number.
  final flightNumberRegExp = RegExp(r'^[a-zA-Z]{2,3}\d{1,4}$');
  // Manager of the desktop environment's sizing.
  final wm = WindowManager.instance;

  @override
  void initState() {
    super.initState();
  }

  // Calls the AviationStack API and returns a Flight object from JSON that matches the key value (IATA) given.
  // Future<Flight?> _callFlightAPI(String iata) async {
  //   const key = 'c1a9697f9b6263fffcb12a94543e68fa';
  //   String url = 'https://api.aviationstack.com/v1/flights?access_key=$key&flight_iata=$iata';
  //   final uri = Uri.parse(url);
  //   final response = await http.get(uri);

  //   if (response.statusCode == 200) {
  //     final body = response.body;
  //     final json = jsonDecode(body) as Map<String, dynamic>;
  //     final data = json['data'] as List<dynamic>;

  //     if (data.isNotEmpty) {
  //       return Flight.fromJson(data.first);
  //     } else {
  //       return null;
  //     }
  //   } else {
  //     throw Exception('Failed to fetch flights. Status: ${response.statusCode}');
  //   }
  // }

  Future<Flight?> _callFlightAPI(String iata) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock flight data similar to what the real API returns
    final mockJson = {
      "flight": {
        "iata": "WZ7905",
        "icao": "WZZ7905",
      },
      "departure": {
        "iata": "CDG",
        "airport": "Charles de Gaulle Airport",
        "estimated": "2025-04-22T17:00:00+00:00",
        "timezone": "Europe/Paris",
      },
      "arrival": {
        "iata": "YYZ",
        "airport": "Lester B. Pearson Airport",
        "scheduled": "2025-04-23T00:00:00+00:00",
        "timezone": "America/Toronto",
      }
    };
    return Flight.fromJson(mockJson);
  }

  // Validates the flight number a user enters.
  // First, it will see if anything was entered at all and relay a unique message for them to do so if not.
  // Then, it compares what the user entered to the RegEx which represents correct formatting.
  // When all of that is verified, it will only now call the API to try and find the flight number in there.
  // Finally, once it does find a flight number in the API, it will proceed to the next page with that flight's data.
  void _validateFlightInput (String flightNumber) async {
    const String errorMessageEmpty = 'You must enter a flight number to continue!';
    const String errorMessageFormat = 'The flight number you entered is invalid! Please use two or three letters at the front and one to four numbers behind them.';
    const String errorMessageCall = 'The flight number you entered could not be found! Please check and try again.';

    if (flightNumber != '') {
      if ((flightNumber.length >= 3 && flightNumber.length <= 7) && (flightNumberRegExp.hasMatch(flightNumber))) {
        
        try {
          final matchedFlight = await _callFlightAPI(flightNumber);
          if (!mounted) return;

          if (matchedFlight != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TimerPage(title: 'timer', flight: matchedFlight,),
              )
            );
          } 

        } 
        catch (e) {
          errorMessage = errorMessageCall;
          _spawnErrorMessage(errorMessage, 150);  
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue,
      body: Center(
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Logo
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

                // Welcome Text
                Text(
                  'Welcome!',
                  style: GoogleFonts.openSans(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 27,
                  ),
                ),

                const SizedBox(height: 24),

                // Instruction Text
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

                // Input Field
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

                // Submit Button
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
      ),
    );
  }

}