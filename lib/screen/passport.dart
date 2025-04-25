/*
  Author:      Colin Bond
  File:        passport.dart
  
  Description: This file provides a hub and convenient display for users, presenting them with
               a timer until their flight begins departing, time in their device's local area,
               an explicit priority status informed by the background color which is checked
               and switched accordingly every second, and finally a passport upload field 
               for display with icons that allow for replacement or deletion.
               Above this, there are two buttons, one backing out to the previous screen so
               that a new flight number can be entered and another toggling a page where the user can
               view their flight details instead, making it easily visible alongside their priority info.
*/

// Imported dependency packages.
// Future class for asynchronous updating.
import 'dart:async';
// Platform detection.
import 'dart:io';
// Route to the next screen.
import 'package:airport_travel_app/screen/detail.dart';
// Material app design, or in other words Google standards for UI.
import 'package:flutter/material.dart';
// Open Sans Font.
import 'package:google_fonts/google_fonts.dart';
// Dynamic advertisement banners.
import 'package:google_mobile_ads/google_mobile_ads.dart';
// Image uploading and display across page visits.
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Image placeholder area.
import 'package:dotted_border/dotted_border.dart';

// This class is the configuration for the state. It holds the values (in this
// case the title and flight) provided by the parent (in this case the App widget) and
// used by the build method of the State. Fields in a Widget subclass are
// always marked "final".
class PassportPage extends StatefulWidget {
  const PassportPage({
    super.key,
    required this.title,
  });

  final String title;

  @override
  State<PassportPage> createState() => _PassportPageState();
}

// This class controls all of the logic for the state of this widget.
class _PassportPageState extends State<PassportPage> {
  // Declare and initialize information displays.
  // The timer display.
  String departTimer = '';
  // The written priority status.
  String priority = '';

  // Declare the timer for constant updating of the program.
  late Timer _clockTimer;
  // Declare an ad unit to be displayed in ad widgets and bool to ensure it loads successfully before proceeding.
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  // Declare to-be image file for the user passport.
  File? passportImage;  
  // Initialize the background colour which changes at certain times.
  Color? _color = Colors.red[400];

  // Load the page including certain external libraries needing initialization (timezones and mobile ads).
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

  // Preload the passport image from the system if it was already given one at some point and there was no deletion.
  // Change the caption depending on this as well.
  Future<void> loadPassportImage() async {
    // Check persistent disk store for a specific path, which the passport upload is set to follow.
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('passport_image_path');
    if (path != null && await File(path).exists()) {
      setState(() {
        passportImage = File(path);
      });
    }
  }

  // Facilitate the ability to upload an image from the gallery to the system for display and further reference.
  Future<void> pickAndSaveImage() async {
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
      passportImage = newImage;
    });
  }

  // Remove a passport from storage.
  Future<void> deleteImage() async {
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
      passportImage = null;
    });
  }

  // Pop up a confirmation of deletion.
  Future<void> confirmDelete() async {
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
      await deleteImage();
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
  void numberPage() {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => NumberPage(title: 'detail'),
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
                              onPressed: numberPage,
                              icon: const Icon(Icons.flight),
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
                              passportImage != null
                              ? Column(
                                  children: [
                                    const SizedBox(height: 35),
                                    Image.file(
                                      passportImage!,
                                      width: 275,
                                      height: 385,
                                      fit: BoxFit.cover,
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    const SizedBox(height: 35),
                                    DottedBorder(
                                      color: Colors.white,
                                      child: SizedBox(
                                        height: 385,
                                        width: 275,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text(
                                                'Upload your passport to display it here.',
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.openSans(color: Colors.white, fontSize: 15),
                                              ),
                                            ),                                            
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 15),
                              // Upload or view passport zone, depending on the current state of the variable to hold it.
                              passportImage != null
                              ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [                                  
                                  IconButton(
                                    onPressed: pickAndSaveImage,
                                    icon: const Icon(Icons.file_upload_outlined),
                                    color: Colors.white,
                                    iconSize: 50,
                                  ),
                                  const SizedBox(width: 25),                
                                  IconButton(
                                    onPressed: confirmDelete,
                                    icon: const Icon(Icons.delete),
                                    color: Colors.white,
                                    iconSize: 50,
                                  ),                                                                    
                                ],
                              )
                              : GestureDetector(
                                onTap: pickAndSaveImage,
                                child: const Icon(
                                  Icons.file_upload_outlined,
                                  color: Colors.white,
                                  size: 50,
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