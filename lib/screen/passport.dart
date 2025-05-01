/*
  Author:      Colin Bond
  File:        passport.dart
  
  Description: This file provides users an opportunity to upload their passport for later display. It features
               a tappable area near the center which will remain so even after a passport is uploaded and
               displayed to promote swift updating of it when necessary. Additionally, icons to delete
               the passport and also navigate to the next screen will only show up if there is a file
               path registered within the app.
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

// Image related packages.
// Select images from gallery.
import 'package:image_picker/image_picker.dart';
// File pathing logic to persist selected image across different page visits.
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Image placeholder area.
import 'package:dotted_border/dotted_border.dart';

// Dynamic advertisement banners.
import 'package:google_mobile_ads/google_mobile_ads.dart';

// Routes to the other screens.
// Flight number entry page.
import 'package:airport_travel_app/screen/number.dart';
// Authentication page for redirection after logout.
import 'auth_gate.dart';

// This class is the configuration for the state. It holds the values (in this
// case the title and flight) provided by the parent (in this case the App widget) and
// used by the build method of the State. Fields in a Widget subclass are
// always marked "final".
class PassportPage extends StatefulWidget {
  const PassportPage({
    super.key,
  });

  @override
  State<PassportPage> createState() => _PassportPageState();
}

// This class controls all of the logic for the state of this widget.
class _PassportPageState extends State<PassportPage> {
  // Declare and initialize information displays.
  // Strings for the passport status message to change depending on if one was uploaded or not.
  String passportMessage = 'Please tap below to select your passport.';
  String passportMessageNoUpload = 'Please tap below to select your passport.';
  String passportMessageYesUpload = 'Tap on your passport to replace it.';

  // Declare an ad unit to be displayed in ad widgets and bool to ensure it loads successfully before proceeding.
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  // Declare to-be image file for the user passport.
  File? passportImage;

  // Load the page including a previously selected image path if there is one found and an ad instance for the page.
  @override
  void initState() {
    super.initState();
    loadPassportImage();
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
        passportMessage = passportMessageYesUpload;
      });
    }
    else {
      setState(() {
        passportMessage = passportMessageNoUpload;
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
      passportMessage = passportMessageYesUpload;
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
      passportMessage = passportMessageNoUpload;
    });
  }

  // Pop up a confirmation of deletion.
  Future<void> confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete'),
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
    super.dispose();
  }

  // Navigate to the third or Flight Number page.
  void _numberPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => NumberPage(passport: passportImage!),
      )
    );
  }

  // Visual appearance of the app.
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
                        // Top row of icons.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Button to log out of account and be able to log in again.
                            IconButton(
                              icon: const Icon(Icons.logout),
                              iconSize: 50,
                              color: Colors.white,
                              tooltip: 'Sign Out',
                              onPressed: confirmLogout
                            )
                          ],
                        ),
                        // Main layout of the screen.                         
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Headings conveying step number, a welcoming message, and instructions for this step.
                              const Text (
                                'Step 1 of 3',
                                style: TextStyle(
                                  color: Colors.white,
                                )
                              ),                                                          
                              const Text(
                                'Welcome!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 5),                              
                              SizedBox(
                                width: 280,
                                child: Text(
                                  passportMessage,
                                  style: const TextStyle(color: Colors.white, fontSize: 15),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Passport selection and display area.
                              GestureDetector(
                                onTap: pickAndSaveImage,
                                child: passportImage != null
                                ? Column(
                                    children: [                                    
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
                                      DottedBorder(
                                        color: Colors.white,
                                        child: const SizedBox(
                                          height: 385,
                                          width: 275,                                        
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.file_upload_outlined,
                                                color: Colors.white,
                                                size: 50,
                                              ),                                                                                        
                                            ],
                                          ),
                                        ),
                                      ),                                    
                                    ],
                                  ),
                              ),
                              const SizedBox(height: 10),
                              // Bottom row of icons, with delete passport and next step.
                              // There must be a passport entry for the ability to delete it or move forward.
                              passportImage != null
                              ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [                                  
                                  IconButton(
                                    onPressed: confirmDelete,
                                    icon: const Icon(Icons.delete),
                                    color: Colors.white,
                                    iconSize: 50,
                                  ), 
                                  const SizedBox(width: 25),                
                                  IconButton(
                                    onPressed: _numberPage,
                                    icon: const Icon(Icons.arrow_forward),
                                    color: Colors.white,
                                    iconSize: 50,
                                  ),                                                                    
                                ],
                              )
                              : const SizedBox(height: 25),
                            ],
                          ),
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