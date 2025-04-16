// Future class for asynchronous updating.
import 'dart:async';
// Platform detection.
import 'dart:io';
// Route to the next screen.
import 'package:airport_travel_app/screen/passport.dart';
// Flight data.
import 'package:airport_travel_app/model/flight.dart';
// Material app design, or in other words Google recommendations for UI.
import 'package:flutter/material.dart';
// Open Sans Font.
import 'package:google_fonts/google_fonts.dart';
// Date manipulation.
import 'package:intl/intl.dart';
// Timezone abbreviation display.
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
// Advertisements.
// import 'package:google_mobile_ads/google_mobile_ads.dart';

// This class is the configuration for the state. It holds the values (in this
// case the title) provided by the parent (in this case the App widget) and
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
  // Initialize information displays.
  String priority = 'Your priority status is Priority 3';
  String departTime = 'Loading...';
  String arriveTime = 'Loading...';
  String date = DateFormat.yMMMMd().format(DateTime.now());
  String currentTime = DateFormat.Hm().format(DateTime.now());
  String departTimer = 'Loading...';
  String departCode = '';
  String arriveCode = '';
  
  // Initialize the background colour which changes at certain times.
  Color? _color = Colors.red[400];
  // Initialize the timer for constant updating of the program.
  late Timer _clockTimer;

  // Declare an ad unit to be displayed in ad widgets and bool to ensure it loads successfully before proceeding.
  // BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();

    // Try to initialize an ad unit to be displayed in ad widgets.
    // Only initialize ads on supported platforms.
    // if (Platform.isAndroid || Platform.isIOS) {
    //   _bannerAd = BannerAd(
    //     adUnitId: 'ca-app-pub-3940256099942544/6300978111',
    //     size: AdSize.banner,
    //     request: AdRequest(),
    //     listener: BannerAdListener(
    //       onAdLoaded: (Ad ad) {
    //         setState(() {
    //           _isAdLoaded = true;
    //         });
    //       },
    //       onAdFailedToLoad: (Ad ad, LoadAdError error) {
    //         ad.dispose();
    //         print('BannerAd failed to load: $error');
    //       },
    //     ),
    //   )..load();
    // }

    _startClock();
    _updateTime();
  }

  void _startClock() {
    Future.delayed(const Duration(seconds: 0), () {
      if (!mounted) return;

      _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _updateTime();
      });
    });
  }

  void _updateTime() {
    // Format raw json departure date and time for timer (workaround using a standard universal date format for API).
    // Remove UTC offset from string data (+00:00 is chopped off of the end).
    String departDateString = widget.flight.departDate.toString().substring(0,19);
    // Send back to date for operations with current time and formatting.
    DateTime departDate = DateTime.parse(departDateString);
    date = DateFormat.yMMMMd().format(departDate);
    // Calculate time until flight.
    Duration difference = departDate.difference(DateTime.now());

    // Format raw json arrival date and time for display (workaround using a standard universal date format for API)
    // Remove UTC offset from string data.
    String arriveDateString = widget.flight.arriveDate.toString().substring(0,19);
    // Send back to date for formatting.
    DateTime arriveDate = DateTime.parse(arriveDateString);

    setState(() {
      if (difference.inMinutes < 90)  {
        _color = Colors.amberAccent[700];
        priority = 'Your priority status is Priority 2';
      }
      if (difference.inMinutes < 45) {
        _color = Colors.greenAccent[700];
        priority = 'Your priority status is Priority 1';
      }
      if (difference.inMinutes < 1 && difference.inSeconds < 1) {
        _color = Colors.black;
        priority = 'Your flight has already left';
        difference = const Duration(hours: 0, minutes: 0, seconds: 0);
      }
      currentTime = DateFormat.jm().format(DateTime.now());
      departTimer = _printDuration(difference);
      departTime = DateFormat.jm().format(departDate);
      departCode = getAbbreviation(departDate, widget.flight.departTimezone);
      arriveTime = DateFormat.jm().format(arriveDate);
      arriveCode = getAbbreviation(arriveDate, widget.flight.arriveTimezone);
    });
  }

  String _printDuration(Duration duration) {
    String negativeSign = duration.isNegative ? '-' : '';
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60).abs());
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60).abs());
    return "$negativeSign${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  String getAbbreviation(DateTime utcTime, String timeZone) {
    final location = tz.getLocation(timeZone);
    final tzTime = tz.TZDateTime.from(utcTime, location);
    return tzTime.timeZoneName;
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  void _welcome() {
    Navigator.pushNamed(context, '/');
  }

  void _passport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PassportPage(title: 'passport', flight: widget.flight,),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called.
    return Scaffold(
      backgroundColor: _color,  
      body: Center(
        child: Column(      
          mainAxisAlignment: MainAxisAlignment.start,
          verticalDirection: VerticalDirection.down,
          children: <Widget>[
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: _welcome, icon: const Icon(Icons.arrow_back), color: Colors.white, iconSize: 50),
                IconButton(onPressed: _passport, icon: const Icon(Icons.badge), color: Colors.white, iconSize: 50),
              ],
            ),
            const SizedBox(height: 125),
            Text(
              departTimer,
              style: GoogleFonts.openSans(color: Colors.white, fontSize: 60, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 5),
            Text(
              'Currently, it is $currentTime.',
              style: GoogleFonts.openSans(color: Colors.white, fontSize: 15)
            ),
            const SizedBox(height: 5),
            Text(
              '$priority.',
              style: GoogleFonts.openSans(color: Colors.white, fontSize: 15)
            ),
            const SizedBox(height: 25),
            Text(
              'Flight Details for ${widget.flight.flightIata}',
              style: GoogleFonts.openSans(color: Colors.white, fontSize: 15)
            ),
            Text(
               '($date)',
               style: GoogleFonts.openSans(color: Colors.white, fontSize: 15)
            ),
            const SizedBox(height: 15),
            Row (
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [                                        
                    const Row(
                      children: [
                        Icon(
                          Icons.flight_takeoff,
                          color: Colors.white,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          widget.flight.departNumber,
                          style: GoogleFonts.openSans(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold)
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          widget.flight.departName,
                          style: GoogleFonts.openSans(color: Colors.white, fontSize: 15)
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          '$departTime $departCode',
                          style: GoogleFonts.openSans(color: Colors.white, fontSize: 15)
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(                  
                  width: 25
                ), 
                Column(
                  children: [                    
                    const Row(
                      children: [
                        Icon(
                          Icons.flight_land,
                          color: Colors.white,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          widget.flight.arriveNumber,
                          style: GoogleFonts.openSans(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold)
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          widget.flight.arriveName,
                          style: GoogleFonts.openSans(color: Colors.white, fontSize: 15)
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          '$arriveTime $arriveCode',
                          style: GoogleFonts.openSans(color: Colors.white, fontSize: 15)
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            // if (_isAdLoaded) 
            //   Container(
            //     width: _bannerAd!.size.width.toDouble(),
            //     height: _bannerAd!.size.height.toDouble(),
            //     child: AdWidget(ad: _bannerAd!),
            //   ),
            const SizedBox(height: 75),  
          ],
        ),
      ),
    );
  }
}