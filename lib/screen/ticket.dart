/*
  Author:      Colin Bond
  File:        ticket.dart
  
  Description: This file provides a hub and convenient display for users, presenting them with
               a timer until their flight begins departing, time in their device's local area,
               an explicit priority status informed by the background color which is checked
               and switched accordingly every second, and finally a ticket upload field 
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
import 'package:airport_travel_app/screen/number.dart';
// Material app design, or in other words Google standards for UI.
import 'package:flutter/material.dart';
// Dynamic advertisement banners.
import 'package:google_mobile_ads/google_mobile_ads.dart';
// Image uploading and display across page visits.
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Image placeholder area.
import 'package:dotted_border/dotted_border.dart';
// Flight model for necessary data about the flight to carry to the details screen.
import 'package:airport_travel_app/model/flight.dart';

// This class is the configuration for the state. It holds the values (in this
// case the title and flight) provided by the parent (in this case the App widget) and
// used by the build method of the State. Fields in a Widget subclass are
// always marked "final".
class TicketPage extends StatefulWidget {
  const TicketPage({
    super.key,
    required this.title,
    required this.flight
  });

  final String title;
  final Flight flight;

  @override
  State<TicketPage> createState() => _TicketPageState();
}

// This class controls all of the logic for the state of this widget.
class _TicketPageState extends State<TicketPage> {
  // Declare and initialize information displays.
  // Strings for the ticket status message to change depending on if one was uploaded or not.
  String ticketMessage = 'Please tap below to select your ticket.';
  String ticketMessageNoUpload = 'Please tap below to select your ticket.';
  String ticketMessageYesUpload = 'Tap on your ticket to replace it.';

  // Declare an ad unit to be displayed in ad widgets and bool to ensure it loads successfully before proceeding.
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  // Declare to-be image file for the user ticket.
  File? ticketImage;

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

  // Preload the ticket image from the system if it was already given one at some point and there was no deletion.
  // Change the caption depending on this as well.
  Future<void> loadticketImage() async {
    // Check persistent disk store for a specific path, which the ticket upload is set to follow.
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('ticket_image_path');
    if (path != null && await File(path).exists()) {
      setState(() {        
        ticketImage = File(path);
        ticketMessage = ticketMessageYesUpload;
      });
    }
    else {
      setState(() {
        ticketMessage = ticketMessageNoUpload;
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
    await prefs.setString('ticket_image_path', newPath);

    // Change the display values accordingly (ticket image will replace dotted box).
    setState(() {
      ticketImage = newImage;
      ticketMessage = ticketMessageYesUpload;
    });
  }

  // Remove a ticket from storage.
  Future<void> deleteImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('ticket_image_path');
    // Only act if there is something on the ticket path.
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      await prefs.remove('ticket_image_path');
    }

    // Change the display values accordingly (dotted box will replace ticket image).
    setState(() {
      ticketImage = null;
      ticketMessage = ticketMessageNoUpload;
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

  // Pop up a confirmation for logging out.
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
                _loginPage();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Navigate back to the first or Welcome page.
  void _loginPage() {
    Navigator.pushNamed(context, '/');
  }

  // Navigate to the third or Flight Number page.
  void _numberPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NumberPage(title: 'number'),
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
                        // Top icons.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Back button to log out of account and be able to log in again.
                            IconButton(
                              onPressed: confirmLogout,
                              icon: const Icon(Icons.logout),
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
                              const Text (
                                'Step 3 of 3',
                                style: TextStyle(
                                  color: Colors.white,
                                )
                              ),                                                          
                              const Text(
                                'Use your Ticket',
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
                                  ticketMessage,
                                  style: const TextStyle(color: Colors.white, fontSize: 15),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 20),
                              GestureDetector(
                                onTap: pickAndSaveImage,
                                child: ticketImage != null
                                ? Column(
                                    children: [                                    
                                      Image.file(
                                        ticketImage!,
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
                              // Upload or view ticket zone, depending on the current state of the variable to hold it.
                              ticketImage != null
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
                                    icon: const Icon(Icons.navigate_next),
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