/*
  Author:      Colin Bond
  File:        detail.dart
  
  Description: This file provides a convenient main page for users after setup, presenting them with:
               - A timer until their flight begins departing.
               - A background colour indicating priority status (>1h30m red, >45m yellow, 45m-0m1s green, >1s black).
               - An explicit priority status informed by the background color. Both are checked
                 and switched accordingly every second.
               - A passport icon that can be clicked to expand the earlier uploaded passport image.
               - A ticket display from the earlier uploaded ticket image that can be clicked to expand it.
               - Some basic flight details without having to expand the ticket.
*/

// Imported dependency packages.

// Dart language native libraries.
// Future class for asynchronous updating.
import 'dart:async';
// File work.
import 'dart:io';

// Material app design, or in other words Google standards for UI.
import 'package:flutter/material.dart';

// Firebase suite for seamless authentication.
// Allow the user to log out.
import 'package:firebase_auth/firebase_auth.dart';

// Date manipulation logic for correct displays.
// Timezone database and an aware version of the usual DateTime that takes different timezones into account.
import 'package:timezone/timezone.dart' as tz;
// Conversion and simplification of various timezones.
import 'package:instant/instant.dart';
// Results formatting for adoption into UI.
import 'package:intl/intl.dart';

// Passport and ticket displays.
import 'package:photo_view/photo_view.dart';

// Dynamic advertisement banners.
import 'package:google_mobile_ads/google_mobile_ads.dart';

// Flight data.
import 'package:airport_travel_app/model/flight.dart';

// Route to the other screens.
// Route to the previous screen to reupload a ticket or even something from earlier during setup.
import 'package:airport_travel_app/screen/ticket.dart';
// Authentication page for redirection after logout.
import 'package:airport_travel_app/screen/auth_gate.dart';


// This class is the configuration for the state. It holds the values (in this
// case the title and flight) provided by the parent (in this case the App widget) and
// used by the build method of the State. Fields in a Widget subclass are
// always marked "final".
class DetailPage extends StatefulWidget {
  const DetailPage({
    super.key,
    required this.passport,
    required this.flight,
    required this.ticket
  });

  final File passport;
  final Flight flight;
  final File ticket;

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

  // Load the page and an ad instance for it.
  @override
  void initState() {
    super.initState();
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

  void expandPassport() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        pageBuilder: (BuildContext context, _, __) {
          return Scaffold(
            backgroundColor: Colors.black.withOpacity(0.5),
            body: Center(
              child: Hero(
                tag: "zoom",
                child: PhotoView(
                  imageProvider: FileImage(widget.passport),
                  backgroundDecoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  minScale: PhotoViewComputedScale.contained * 0.8,
                  maxScale: PhotoViewComputedScale.covered * 1.8,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void expandTicket() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        pageBuilder: (BuildContext context, _, __) {
          return Scaffold(
            backgroundColor: Colors.black.withOpacity(0.5),
            body: Center(
              child: Hero(
                tag: "zoom",
                child: PhotoView(
                  imageProvider: FileImage(widget.ticket),
                  backgroundDecoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  minScale: PhotoViewComputedScale.contained * 0.8,
                  maxScale: PhotoViewComputedScale.covered * 1.8,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Pop up a visually striking confirmation before logging out.
  Future<void> confirmLogout() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to log out?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop();
                _logOut();
              },
            ),
          ],
        );
      },
    );
  }

  // Navigate back to the first page which will let the user re-authenticate.
  void _logOut() async {
    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) {
        return;
      }
      else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AuthGate(),
          )
        );
      }

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      print('Sign out error: $e');
    }
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  // Navigate to the third or Passport page.
  void _ticketPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TicketPage(passport: widget.passport, flight: widget.flight,),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top row of icons.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Back button to return to ticket selection.
                            IconButton(
                              onPressed: _ticketPage,
                              icon: const Icon(Icons.arrow_back),
                              color: Colors.white,
                              iconSize: 50,
                            ),                            
                            // Passport button to move the uploaded passport image to front and allow zooming.
                            IconButton(
                              onPressed: expandPassport,
                              icon: const Icon(Icons.badge),
                              color: Colors.white,
                              iconSize: 50,
                            ),
                            // Button to log out of account and be able to log in again.
                            IconButton(
                              icon: const Icon(Icons.logout),
                              iconSize: 50,
                              color: Colors.white,
                              tooltip: 'Sign Out',
                              onPressed: confirmLogout
                            ),
                          ],
                        ),                        
                        // Main layout of the screen.
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Headings conveying the timer and priority status.
                              Text(
                                departTimer,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 50,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                priority,
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 25),
                              // Ticket preview which can also move the uploaded image to front and allow zooming.
                              GestureDetector(
                                onTap: expandTicket,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.file(
                                    widget.ticket,
                                    width: 275,
                                    height: 128,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 25),
                              // Headings conveying the flight details below.
                              Text(
                                'Flight Details for ${widget.flight.flightIata}',
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                '($date)',
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 5),
                            ],
                          ),
                        ),
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
                                  Text(
                                    '$departTime $departCode',
                                    style: const TextStyle(color: Colors.white, fontSize: 15),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    widget.flight.departNumber,
                                    style: const TextStyle(
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
                                    style: const TextStyle(color: Colors.white, fontSize: 15),
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
                                  Text(
                                    '$arriveTime $arriveCode',
                                    style: const TextStyle(color: Colors.white, fontSize: 15),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    widget.flight.arriveNumber,
                                    style: const TextStyle(
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
                                    style: const TextStyle(color: Colors.white, fontSize: 15),
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
                // Ad pinned to very bottom.
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