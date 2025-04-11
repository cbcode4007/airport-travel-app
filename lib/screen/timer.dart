import 'dart:async';
import 'package:airport_travel_app/model/flight.dart';
import 'package:flutter/material.dart';
// Open Sans Font.
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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
  // Initially empty error message String for later assignment.
  String errorMessage = '';

  late Timer _clockTimer;
  late String _currentTime = DateFormat.Hm().format(DateTime.now());
  late String _date = DateFormat.Hm().format(DateTime.now());
  late String _departureTime = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _startClock();
  }

  void _startClock() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _updateTime();
      });
    });
  }

  void _updateTime() {
    // Convert now into airport timezone?

    final now = DateTime.now();
    _date = DateFormat.yMd().format(now);

    DateTime departDateLocal = DateTime.parse(widget.flight.departDate.toIso8601String()).toLocal();

    Duration difference = departDateLocal.toUtc().difference(now.toLocal());
    // Duration difference = now.difference(widget.flight.departDate);

    DateTime departDate = widget.flight.departDate.toLocal();
    DateTime departDateUTC = widget.flight.departDate.toUtc();
    DateTime nowUTC = now.toUtc();
    DateTime nowLocal = now.toLocal();
    print('Dep UTC:    $departDateUTC');
    print('Dep no UTC: $departDateLocal');
    print('Now UTC:    $nowUTC');
    print('Now no UTC: $nowLocal');
    print(difference);
    print(widget.flight.flightIcao);

    setState(() {
      _currentTime = DateFormat.Hm().format(now);
      _departureTime = _printDuration(difference);
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  String _printDuration(Duration duration) {
    String negativeSign = duration.isNegative ? '-' : '';
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60).abs());
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60).abs());
    return "$negativeSign${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  void _backToWelcome() {
    Navigator.pushNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called.
    return Scaffold(
      backgroundColor: Colors.red[400],  
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).         
          mainAxisAlignment: MainAxisAlignment.center, 
          children: <Widget>[
            IconButton(onPressed: _backToWelcome, icon: const Icon(Icons.arrow_back_ios_new), color: Colors.white,),
            Text(
              _departureTime,
              style: GoogleFonts.openSans(color: Colors.white, fontSize: 60, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 15),
            Text(
              'Currently, it is $_currentTime.',
              style: GoogleFonts.openSans(color: Colors.white, fontSize: 15)
            ),
            const SizedBox(height: 5),
            Text(
              'Your priority status is Priority 3.',
              style: GoogleFonts.openSans(color: Colors.white, fontSize: 15)
            ),
            const SizedBox(height: 60),
            Text(
              'Flight Details for ${widget.flight.flightIata}/${widget.flight.flightIcao} ($_date)',
              style: GoogleFonts.openSans(color: Colors.white, fontSize: 15)
            ),
            const SizedBox(height: 75),  
          ],
        ),
      ),
    );
  }
}