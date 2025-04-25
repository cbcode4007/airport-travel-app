/*
  Author:      Colin Bond
  File:        detail.dart
  
  Description: This file provides a hub and convenient display for users, presenting them with
               a timer until their flight begins departing, time in their device's local area,
               an explicit priority status informed by the background color which is checked
               and switched accordingly every second, and finally details about the flight.
               Above this, there are two buttons, one backing out to the previous screen so
               that a new flight number can be entered and another toggling a page where the user can
               upload their passport for in-app display as well as delete it instead,
               making it easily visible alongside their priority info.
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
import 'package:instant/instant.dart';
// Dynamic advertisement banners.
import 'package:google_mobile_ads/google_mobile_ads.dart';

// This class is the configuration for the state. It holds the values (in this
// case the title and flight) provided by the parent (in this case the App widget) and
// used by the build method of the State. Fields in a Widget subclass are
// always marked "final".
class DetailPage extends StatefulWidget {
  const DetailPage({
    super.key,
    required this.title,
    required this.flight,
  });

  final String title;
  final Flight flight;

  @override
  State<DetailPage> createState() => _DetailPageState();
}

// This class controls all of the logic for the state of this widget.
class _DetailPageState extends State<DetailPage> {
  // Declare and initialize information displays.
  // The timer display.
  String departTimer = '';
  // The written priority status.
  String priority = '';
  // The date that appears with the flight information, which will be of the departure.
  String date = DateFormat.yMMMMd().format(DateTime.now());
  // The time that appears in the departure column.
  String departTime = '';
  // The abbreviation that appears behind departure time.
  String departCode = '';
  // The time that appears in the arrival column.
  String arriveTime = '';
  // The abbreviation that appears behind arrival time.
  String arriveCode = '';

  // Declare the timer for constant updating of the program.
  late Timer _clockTimer;
  // Declare an ad unit to be displayed in ad widgets and bool to ensure it loads successfully before proceeding.
  BannerAd? _bannerAd;
  bool _isAdLoaded = false; 
  // Initialize the background colour which changes at certain times.
  Color? _color = Colors.red[400];

  // Load the page including certain external libraries needing initialization (timezones and mobile ads).
  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    initialVariables();
    startTimer();
    updatePage();
    MobileAds.instance.initialize();
    loadAd();
  }

  // Set declared variables that need to be initialized during runtime once but never changed after that.
  void initialVariables() {
    // Set day, month and year to how they are in the departure timezone.
    date = DateFormat.yMMMMd().format(widget.flight.departDate);
    // Get the departure time to display.
    departTime = DateFormat.jm().format(widget.flight.departDate);
    // Get the departure timezone's short form (e.g. EST) to display alongside it.
    departCode = getAbbreviation(widget.flight.departDate, widget.flight.departTimezone);
    // Get the arrival time to display.
    arriveTime = DateFormat.jm().format(widget.flight.arriveDate);
    // Get the arrival timezone's short form (e.g. EST) to display alongside it.
    arriveCode = getAbbreviation(widget.flight.arriveDate, widget.flight.arriveTimezone);
  }

  // Calls the function to update the page every second for a seamless timer and other current information.
  void startTimer() {
    Future.delayed(const Duration(seconds: 0), () {
      if (!mounted) return;

      _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        updatePage();
      });
    });
  }

  // Refreshes timer and the rest of the page while running calculations to confirm everything is still right.
  void updatePage() {
    // Time difference resolution (timer until departure).
    // Set current date to how it is in the departure date timezone.
    DateTime localDate = dateTimeToZone(zone: getAbbreviation(DateTime.now(), widget.flight.departTimezone), datetime: DateTime.now());
    Duration difference = widget.flight.departDate.difference(localDate);

    // UI updates.
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
    });
    // Get the difference between current and departure times to display in readable format, or rather the timer.
    departTimer = printDuration(difference);
  }

  // Format duration objects such as differences, specifically the timer, in human readable format.
  String printDuration(Duration duration) {
    // String negativeSign = duration.isNegative ? '-' : '';
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60).abs());
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60).abs());
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
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
  void welcomePage() {
    Navigator.pushNamed(context, '/');
  }

  // Navigate to the third or Passport page.
  void passportPage() {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => PassportPage(title: 'passport', flight: widget.flight,),
    //   )
    // );
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
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top icons.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Back button to enter another flight IATA.
                            IconButton(
                              onPressed: welcomePage,
                              icon: const Icon(Icons.arrow_back),
                              color: Colors.white,
                              iconSize: 50,
                            ),
                            // Passport button to add a passport image to view in the app.
                            IconButton(
                              onPressed: passportPage,
                              icon: const Icon(Icons.badge),
                              color: Colors.white,
                              iconSize: 50,
                            ),
                          ],
                        ),
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
                              Text(
                                priority,
                                style: GoogleFonts.openSans(color: Colors.white, fontSize: 15),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 100),
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
                              const SizedBox(height: 25),
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