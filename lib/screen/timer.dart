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
// Dynamic advertisement banners.
import 'package:google_mobile_ads/google_mobile_ads.dart';

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
  // Declare and initialize information displays.
  String priority = '';
  String departTime = '';
  String arriveTime = '';
  String date = DateFormat.yMMMMd().format(DateTime.now());
  String currentTime = DateFormat.Hm().format(DateTime.now());
  String departTimer = '';
  String departCode = '';
  String arriveCode = '';
  // Declare timezone calculation values.
  String rawTime = '';
  String tzName = '';
  // Declare the timer for constant updating of the program.
  late Timer _clockTimer;
  // Initialize the background colour which changes at certain times.
  Color? _color = Colors.red[400];

  // Declare an ad unit to be displayed in ad widgets and bool to ensure it loads successfully before proceeding.
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _startClock();
    _updateTime();
    MobileAds.instance.initialize();
    loadAd();
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

    // Initialize values to calculate departure timezone for accurate counting.
    rawTime = widget.flight.departDate.toString();
    tzName = widget.flight.departTimezone;
    // Parse the raw time without a timezone attached.
    DateTime naiveLocalTime = DateTime.parse(rawTime);
    // Look up the timezone location.
    final location = tz.getLocation(tzName);
    // Apply timezone to the naive time.
    final tz.TZDateTime tzDepartDate = tz.TZDateTime.from(naiveLocalTime, location);

    // Format raw json departure date and time for timer (workaround using a standard universal date format for API).
    // Remove UTC offset from string data (+00:00 is chopped off of the end).
    // String departDateString = widget.flight.departDate.toString().substring(0,19);
    // Send back to date for operations with current time and formatting.
    // DateTime departDate = DateTime.parse(departDateString);
    // date = DateFormat.yMMMMd().format(departDate);

    // Set day, month and year to how they are in the departure timezone.
    date = DateFormat.yMMMMd().format(tzDepartDate);
    // Calculate time until flight, every second to keep the clock updated.
    Duration difference = tzDepartDate.difference(DateTime.now());

    // Format raw json arrival date and time for display (workaround using a standard universal date format for API).
    // This can remain a naive date since it is not used in calculation.
    // Remove UTC offset from string data.
    String arriveDateString = widget.flight.arriveDate.toString().substring(0,19);
    // Send back to date for formatting.
    DateTime arriveDate = DateTime.parse(arriveDateString);

    setState(() {
      priority = 'Your priority status is Priority 3.';
      if (difference.inMinutes < 90)  {
        _color = Colors.amberAccent[700];
        priority = 'Your priority status is Priority 2.';
      }
      if (difference.inMinutes < 45) {
        _color = Colors.greenAccent[700];
        priority = 'Your priority status is Priority 1.';
      }
      if (difference.inMinutes < 1 && difference.inSeconds < 1) {
        _color = Colors.black;
        priority = 'Your flight has already left.';
        difference = const Duration(hours: 0, minutes: 0, seconds: 0);
      }
      currentTime = DateFormat.jm().format(DateTime.now());
      departTimer = _printDuration(difference);
      departTime = DateFormat.jm().format(tzDepartDate);
      departCode = getAbbreviation(tzDepartDate, widget.flight.departTimezone);
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

  void loadAd() async {
    // Try to initialize an ad unit to be displayed in ad widgets.
    // Only initialize ads on supported platforms.
    if (Platform.isAndroid || Platform.isIOS) {
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
    return Scaffold(
      backgroundColor: _color,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                // Top content (scrollable if needed)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top icons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: _welcome,
                              icon: const Icon(Icons.arrow_back),
                              color: Colors.white,
                              iconSize: 50,
                            ),
                            IconButton(
                              onPressed: _passport,
                              icon: const Icon(Icons.badge),
                              color: Colors.white,
                              iconSize: 50,
                            ),
                          ],
                        ),

                        const SizedBox(height: 93),

                        // Timer & time info
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
                                'Currently, it is $currentTime.',
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

                        // Flight details row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
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
                  child: _bannerAd == null
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