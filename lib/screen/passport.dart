/*
  Author:      Colin Bond
  File:        passport.dart
  Description: This file provides an area to upload and display a passport with the background color from
               last page visible. Users can tap on their uploaded passport to replace it, or
               tap on a garbage icon that appears when there is a passport to delete it.
               It is a simpler way to show priority as well as credentials.
*/

// Imported dependency packages.
// Future class for asynchronous updating.
import 'dart:async';
// Route to the previous screen.
import 'package:airport_travel_app/screen/timer.dart';
// Flight data to determine background colour.
import 'package:airport_travel_app/model/flight.dart';
// Material app design, or in other words Google standards for UI.
import 'package:flutter/material.dart';
// Open Sans Font.
import 'package:google_fonts/google_fonts.dart';
// Image uploading and display across page visits.
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Image placeholder area.
import 'package:dotted_border/dotted_border.dart';
// Timezone logic for correct background display.
import 'package:timezone/timezone.dart' as tz;
// Dynamic advertisement banners.
import 'package:google_mobile_ads/google_mobile_ads.dart';

// This class is the configuration for the state. It holds the values (in this
// case the title and flight) provided by the parent (in this case the App widget) and
// used by the build method of the State. Fields in a Widget subclass are
// always marked "final".
class PassportPage extends StatefulWidget {
  const PassportPage({
    super.key,
    required this.title,
    required this.flight,
  });

  final String title;
  final Flight flight;

  @override
  State<PassportPage> createState() => _PassportPageState();
}

// This class controls all of the logic for the state of this widget.
class _PassportPageState extends State<PassportPage> {
  // Variables to be updated in code later.
  // Initially empty error message String for later assignment.
  String errorMessage = 'Loading...';
  // Initialize the message that indicates whether passport should be uploaded or if there is and it can be expanded.
  String fileUploadStatus = '';
  String noUpload = 'Upload your passport to display it in the box below.';
  String yesUpload = 'Tap your passport to replace it with another image.';
  // Initialize the background colour which changes at certain times.
  Color? _color = Colors.red[400];
  // Initialize the timer for constant updating of the program.
  late Timer _clockTimer;
  // Declare to-be image file for the user passport.
  File? _passportImage;
  // Declare an ad unit to be displayed in ad widgets and bool to ensure it loads successfully before proceeding.
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  // Load the page including certain external libraries needing initialization (mobile ads).
  @override
  void initState() {
    super.initState();
    _startClock();
    _updateTime();
    _loadPassportImage();
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
    // Calculate time until flight, using both times from the depart timezone, each second to keep the clock updated.
    Duration difference = tzDepartDate.difference(tzCurrentDate);

    // Change background colour depending on how close the current time is to the departure; default is red.
    setState(() {
      // When there is less than an hour and 30 minutes left, go up a priority, transitioning to yellow.
      if (difference.inMinutes < 90)  {
        _color = Colors.amberAccent[700];
      }
      // When there is less than 45 minutes left, go up to the highest priority, transitioning to green.
      if (difference.inMinutes < 45) {
        _color = Colors.greenAccent[700];
      }
      // When the flight has already left, for now, stop the countdown and remove priority colour.
      if (difference.inMinutes < 1 && difference.inSeconds < 1) {
        _color = Colors.black;
        difference = const Duration(hours: 0, minutes: 0, seconds: 0);
      }
    });
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

  // Navigate back to the previous or Timer page.
  void _timer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TimerPage(title: 'timer', flight: widget.flight,),
      )
    );
  }

  // Preload the passport image from the system if it was already given one at some point and there was no deletion.
  // Change the caption depending on this as well.
  Future<void> _loadPassportImage() async {
    // Check persistent disk store for a specific path, which the passport upload is set to follow.
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('passport_image_path');
    if (path != null && await File(path).exists()) {
      setState(() {
        _passportImage = File(path);
        fileUploadStatus = yesUpload;
      });
    }
    else {
      setState(() {
        fileUploadStatus = noUpload;
      });
    }
  }

  // Facilitate the ability to upload an image from the gallery to the system for display and further reference.
  Future<void> _pickAndSaveImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    // Exit the function whenever there is no gallery image picked to upload.
    if (image == null) return;

    // Create a path for storage and access of the uploaded image.
    final appDir = await getApplicationDocumentsDirectory();
    final newPath = '${appDir.path}/${image.name}';
    final newImage = await File(image.path).copy(newPath);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('passport_image_path', newPath);

    // Change the display values accordingly (passport image will replace dotted box).
    setState(() {
      _passportImage = newImage;
      fileUploadStatus = yesUpload;
    });
  }

  // Remove a passport from storage.
  Future<void> _deleteImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('passport_image_path');
    // Only act if there is something on the passport path.
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      await prefs.remove('passport_image_path');
    }

    // Change the display values accordingly (dotted box will replace passport image).
    setState(() {
      _passportImage = null;
      fileUploadStatus = noUpload;
    });
  }

  // Pop up a confirmation of deletion.
  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Passport Image'),
        content: const Text('Are you sure you want to delete this image from the app?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteImage();
    }
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
                // Main scrollable content.
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top icon, the back button to view timer and flight details.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: _timer,
                              icon: const Icon(Icons.arrow_back),
                              color: Colors.white,
                              iconSize: 50,
                            ),
                          ],
                        ),
                        const SizedBox(height: 50),
                        // Instructions that shift with the inclusion of a passport or not.                        
                        Text(
                          fileUploadStatus,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.openSans(color: Colors.white, fontSize: 15),
                        ),
                        const SizedBox(height: 25),
                        // Upload or view passport zone, depending on the current state of the variable to hold it.
                        GestureDetector(
                          onTap: _pickAndSaveImage,
                          child: _passportImage != null
                              ? Column(
                                  children: [
                                    Image.file(
                                      _passportImage!,
                                      width: 275,
                                      height: 385,
                                      fit: BoxFit.cover,
                                    ),
                                    const SizedBox(height: 15),
                                    IconButton(
                                      onPressed: _confirmDelete,
                                      icon: const Icon(Icons.delete, color: Colors.white),
                                      iconSize: 50,
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    const SizedBox(height: 50),
                                    DottedBorder(
                                      color: Colors.white,
                                      child: const SizedBox(
                                        height: 385,
                                        width: 275,
                                        child: Icon(
                                          Icons.file_upload_outlined,
                                          color: Colors.white,
                                          size: 75,
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