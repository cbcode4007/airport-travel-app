/*
  Author:      Colin Bond
  File:        home.dart
  
  Description: This file provides an initial page for the Airport Travel Application, where users will
               enter a flight number to proceed to its timer and corresponding priority interface, if it exists.
               Contains additional validation to only call the API when absolutely necessary, as uses are limited.
*/

// Imported dependency packages.
// Encode and decode JSON for processing.
import 'dart:convert';
import 'dart:io';
// Route to the previous screen.
import 'package:airport_travel_app/screen/passport.dart';
// Route to the next screen.
import 'package:airport_travel_app/screen/ticket.dart';
// Translate raw JSON into Flight objects that can be further processed.
import 'package:airport_travel_app/model/flight.dart';
// Material app design, or in other words Google standards for UI.
import 'package:flutter/material.dart';
// API calls, retrieving crucial information about a specified flight.
import 'package:http/http.dart' as http;
// Dynamic advertisement banners.
import 'package:google_mobile_ads/google_mobile_ads.dart';

// This class is the configuration for the state. It holds the values (in this
// case the title) provided by the parent (in this case the App widget) and
// used by the build method of the State. Fields in a Widget subclass are
// always marked "final".
class NumberPage extends StatefulWidget {
  const NumberPage({super.key, required this.passport});
  final File passport;
  @override
  State<NumberPage> createState() => _NumberPageState();
}

// This class controls all of the logic for the state of this widget.
class _NumberPageState extends State<NumberPage> {
  // Initially empty error message String for later assignment.
  String errorMessage = '';
  // Controller for flight IATA text field extraction and clearing.
  final TextEditingController _controller = TextEditingController();
  // Regular expression to check correct format against user input flight IATA.
  final flightNumberRegExp = RegExp(r'^[a-zA-Z]{2,3}\d{1,4}$');

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

  // Calls the AviationStack API and returns a Flight object from JSON that matches the key value (IATA) given.
  // Future<Flight?> _callFlightAPI(String iata) async {
  //   // API Credentials.
  //   const key = 'a5cba517fdce175c2efdef4c6c2459e6';
  //   // Link to the request.
  //   String url = 'https://api.aviationstack.com/v1/flights?access_key=$key&flight_iata=$iata';
  //   // Pass a unique resource identifier object.
  //   final uri = Uri.parse(url);
  //   final response = await http.get(uri);
  //   // The request was successfully read and responded to.
  //   if (response.statusCode == 200) {
  //     final body = response.body;
  //     final json = jsonDecode(body) as Map<String, dynamic>;
  //     final data = json['data'] as List<dynamic>;
  //     // What was returned is not an empty string, and should therefore be something in the API.
  //     if (data.isNotEmpty) {
  //       // Return only focused, important fields for this use case, incorporating them into the Flight model.
  //       return Flight.fromJson(data.first);
  //     } else {
  //       return null;
  //     }
  //   } else {
  //     throw Exception('Failed to fetch flights. Status: ${response.statusCode}');
  //   }
  // }

  // Return a preset Flight object made out of mock data for testing.
  Future<Flight?> _callFlightAPI(String iata) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock flight data similar to what the real API returns
    final mockJson = {
      "flight": {
        "iata": "AC8192",
        "icao": "ACA8192",
      },
      "departure": {
        "iata": "YVR",
        "airport": "Vancouver International",
        "estimated": "2025-04-25T13:55:00+00:00",
        "timezone": "America/Vancouver",
      },
      "arrival": {
        "iata": "YQR",
        "airport": "Regina",
        "scheduled": "2025-04-25T13:02:00+00:00",
        "timezone": "America/Regina",
      }
    };
    return Flight.fromJson(mockJson);
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
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => TicketPage(passport: widget.passport, flight: matchedFlight,),
              )
            );
          }
          else {
            errorMessage = errorMessageCall;
            _spawnErrorMessage(errorMessage);
          } 

        } 
        catch (e) {
           throw Exception(e);
        }
      }
      else {
        errorMessage = errorMessageFormat;
        _spawnErrorMessage(errorMessage);
      }
    }
    else {
      errorMessage = errorMessageEmpty;
      _spawnErrorMessage(errorMessage);
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

  void _passportPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const PassportPage(),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                // Top content (scrollable if needed).
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top icons.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Back button to log out of account and be able to log in again.
                            IconButton(
                              onPressed: _passportPage,
                              icon: const Icon(Icons.arrow_back),
                              color: Colors.white,
                              iconSize: 50,
                            ),
                          ],
                        ),
                        const SizedBox(height: 75),
                        const Icon(
                            Icons.flight,
                            color: Colors.white,
                            size: 75,
                        ),
                         
                        // Timer heading & prioritconst SizedBox(height: 15),y info.
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text (
                                'Step 2 of 3',
                                style: TextStyle(
                                  color: Colors.white,
                                )
                              ),                                                          
                              const Text(
                                'Catch your Flight',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 25),
                              const Text (
                                'Please enter your flight number.',
                                style: TextStyle(
                                  color: Colors.white,
                                )
                              ),
                              const SizedBox(height: 15),
                              
                              Center(
                              child: SizedBox(
                                width: 280,
                                child: TextField(
                                  controller: _controller,
                                  style: const TextStyle(color: Colors.white, fontSize: 15),
                                  cursorColor: Colors.white,
                                  decoration: const InputDecoration(
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white70),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white),
                                    ),
                                    hintText: 'AAA####',
                                    hintStyle: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                              const SizedBox(height:20),

                              // Submit button
                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    _validateFlightInput(_controller.text);
                                    _controller.clear();
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    fixedSize: const Size(150, 40),
                                  ),
                                  child: const Text(
                                    'Submit',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.lightBlue,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Ad pinned to bottom.
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: _isAdLoaded == false
                  ? const SizedBox(
                      width: 320,
                      height: 50,
                    )
                  : SizedBox(
                      width: _bannerAd!.size.width.toDouble(),
                      height: _bannerAd!.size.height.toDouble(),
                      child: AdWidget(ad: _bannerAd!),
                    ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}