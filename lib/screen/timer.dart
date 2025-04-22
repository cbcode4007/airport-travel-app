/*
  Author:      Colin Bond
  File:        timer.dart
  Description: This file provides a hub and convenient display for users, presenting them with
               a timer until their flight begins departing, time in their device's local area,
               an explicit priority status informed by the background color which is checked
               and switched accordingly every second, and finally details about the flight.
               Above this, there are two buttons, one backing out to the previous screen so
               that a new flight number can be entered and another enabling the user to
               upload their passport making it easily visible alongside the priority color.
*/

// Imported dependency packages.
// Future class for asynchronous updating.
import 'dart:async';
// Platform detection.
import 'dart:io';
// Route to the next screen.
import 'package:airport_travel_app/screen/passport.dart';
// Flight data.
import 'package:airport_travel_app/model/flight.dart';
// Material app design, or in other words Google standards for UI.
import 'package:flutter/material.dart';
// Open Sans Font.
import 'package:google_fonts/google_fonts.dart';
// Date manipulation.
import 'package:intl/intl.dart';
// Timezone logic for correct displays.
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
// Dynamic advertisement banners.
import 'package:google_mobile_ads/google_mobile_ads.dart';

// This class is the configuration for the state. It holds the values (in this
// case the title and flight) provided by the parent (in this case the App widget) and
// used by the build method of the State. Fields in a Widget subclass are
// always marked "final".
class TimerPage extends StatefulWidget {
  const TimerPage({
    super.key,
    required this.title,
    required this.flight,
  });

  final String title;
  final Flight flight;

  @override
  State<TimerPage> createState() => _TimerPageState();
}

// This class controls all of the logic for the state of this widget.
class _TimerPageState extends State<TimerPage> {
  // Variables to be updated in code later.
  // Declare and initialize information displays.
  String priority = '';
  String departTime = '';
  String arriveTime = '';
  String date = DateFormat.yMMMMd().format(DateTime.now());
  String currentTime = DateFormat.Hm().format(DateTime.now());
  String departTimer = '';
  String departCode = '';
  String arriveCode = '';
  // Declare the timer for constant updating of the program.
  late Timer _clockTimer;
  // Initialize the background colour which changes at certain times.
  Color? _color = Colors.red[400];

  // Declare an ad unit to be displayed in ad widgets and bool to ensure it loads successfully before proceeding.
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  // Load the page including certain external libraries needing initialization (timezones and mobile ads).
  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    startClock();
    _updateTime();
    MobileAds.instance.initialize();
    loadAd();
  }

  void startClock() {
    Future.delayed(const Duration(seconds: 0), () {
      if (!mounted) return;

      _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _updateTime();
      });
    });
  }

  // Refreshes timer and the rest of the page while running calculations to confirm everything is still right.
  void _updateTime() {
    // Initialize values to calculate departure timezone for accurate counting and display.
    String rawTime = widget.flight.departDate.toString();
    String tzName = widget.flight.departTimezone;
    // Parse the raw time without a timezone attached.
    DateTime naiveLocalTime = DateTime.parse(rawTime);
    // Look up the timezone location.
    var location = tz.getLocation(tzName);
    // Apply timezone to the naive time and DateTime.now() for counter calculation.
    final tz.TZDateTime tzDepartDate = tz.TZDateTime.from(naiveLocalTime, location);
    final tz.TZDateTime tzCurrentDate = tz.TZDateTime.from(DateTime.now(), location);

    // Set day, month and year to how they are in the departure timezone.
    date = DateFormat.yMMMMd().format(tzDepartDate);
    // Calculate time until flight, using both times from the depart timezone, each second to keep the clock updated.
    Duration difference = tzDepartDate.difference(tzCurrentDate);

    // Initialize values to calculate arrival timezone for accurate display.
    rawTime = widget.flight.arriveDate.toString();
    tzName = widget.flight.arriveTimezone;
    // Parse the raw time without a timezone attached.
    naiveLocalTime = DateTime.parse(rawTime);
    // Look up the timezone location.
    location = tz.getLocation(tzName);
    // Apply timezone to the naive time and DateTime.now() for calculation.
    final tz.TZDateTime tzArriveDate = tz.TZDateTime.from(naiveLocalTime, location);

    // Change background colour depending on how close the current time is to the departure; default is red.
    setState(() {
      // Default and lowest priority.
      priority = 'Your priority status is Priority 3.';
      // When there is less than an hour and 30 minutes left, go up a priority, transitioning to yellow.
      if (difference.inMinutes < 90)  {
        _color = Colors.amberAccent[700];
        priority = 'Your priority status is Priority 2.';
      }
      // When there is less than 45 minutes left, go up to the highest priority, transitioning to green.
      if (difference.inMinutes < 45) {
        _color = Colors.greenAccent[700];
        priority = 'Your priority status is Priority 1.';
      }
      // When the flight has already left, for now, stop the countdown and remove priority as well as colour.
      if (difference.inMinutes < 1 && difference.inSeconds < 1) {
        _color = Colors.black;
        priority = 'Your flight has already left.';
        difference = const Duration(hours: 0, minutes: 0, seconds: 0);
      }

      // Get the current local time to display in human readable format.
      currentTime = DateFormat.jm().format(DateTime.now());
      // Get the difference between current and departure times to display in readable format, or rather the timer.
      departTimer = _printDuration(difference);
      // Get the departure time to display.
      departTime = DateFormat.jm().format(tzDepartDate);
      // Get the departure timezone's short form (e.g. EST) to display alongside it.
      departCode = getAbbreviation(tzDepartDate, widget.flight.departTimezone);
      // Get the arrival time to display.
      arriveTime = DateFormat.jm().format(tzArriveDate);
      // Get the arrival timezone's short form (e.g. EST) to display alongside it.
      arriveCode = getAbbreviation(tzArriveDate, widget.flight.arriveTimezone);
    });
  }

  // Format duration objects such as differences, specifically the timer, in human readable format.
  String _printDuration(Duration duration) {
    String negativeSign = duration.isNegative ? '-' : '';
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60).abs());
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60).abs());
    return "$negativeSign${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  // Get the short form or code of a given timezone using the timezone import database.
  String getAbbreviation(DateTime utcTime, String timeZone) {
    final location = tz.getLocation(timeZone);
    final tzTime = tz.TZDateTime.from(utcTime, location);
    return tzTime.timeZoneName;
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
            print('BannerAd failed to load: $error');
          },
        ),
      )..load();
    }
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  // Navigate back to the first or Welcome page.
  void _welcome() {
    Navigator.pushNamed(context, '/');
  }

  // Navigate to the third or Passport page.
  void _passport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PassportPage(title: 'passport', flight: widget.flight,),
      )
    );
  }

  // Visual appearance of the app.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _color,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                // Top content (scrollable if needed).
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top icons.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Back button to enter another flight IATA.
                            IconButton(
                              onPressed: _welcome,
                              icon: const Icon(Icons.arrow_back),
                              color: Colors.white,
                              iconSize: 50,
                            ),
                            // Passport button to add a passport image to view in the app.
                            IconButton(
                              onPressed: _passport,
                              icon: const Icon(Icons.badge),
                              color: Colors.white,
                              iconSize: 50,
                            ),
                          ],
                        ),
                        const SizedBox(height: 93),
                        // Timer heading & priority info.
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                departTimer,
                                style: GoogleFonts.openSans(
                                  color: Colors.white,
                                  fontSize: 50,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 15),
                              Text(
                                'It is $currentTime in your area.',
                                style: GoogleFonts.openSans(color: Colors.white, fontSize: 15),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                priority,
                                style: GoogleFonts.openSans(color: Colors.white, fontSize: 15),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 25),
                              Text(
                                'Flight Details for ${widget.flight.flightIata}',
                                style: GoogleFonts.openSans(color: Colors.white, fontSize: 15),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                '($date)',
                                style: GoogleFonts.openSans(color: Colors.white, fontSize: 15),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        // Flight details row.
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              // Departure information column.
                              child: Column(
                                children: [
                                  const Icon(Icons.flight_takeoff, color: Colors.white, size: 50),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$departTime $departCode',
                                    style: GoogleFonts.openSans(color: Colors.white, fontSize: 15),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    widget.flight.departNumber,
                                    style: GoogleFonts.openSans(
                                      color: Colors.white,
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    widget.flight.departName,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.openSans(color: Colors.white, fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 25),
                            Expanded(
                              // Arrival information column.
                              child: Column(
                                children: [
                                  const Icon(Icons.flight_land, color: Colors.white, size: 50),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$arriveTime $arriveCode',
                                    style: GoogleFonts.openSans(color: Colors.white, fontSize: 15),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    widget.flight.arriveNumber,
                                    style: GoogleFonts.openSans(
                                      color: Colors.white,
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    widget.flight.arriveName,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.openSans(color: Colors.white, fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                          ],
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