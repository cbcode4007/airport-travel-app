/*
  Author:      Colin Bond
  File:        ticket.dart
  
  Description: This file provides users an opportunity to upload their ticket for later display. It features
               a tappable area near the center which will remain so even after a ticket is uploaded and
               displayed to promote swift updating of it when necessary. Additionally, icons to delete
               the ticket and also navigate to the next screen will only show up if there is a file
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

// Flight model for necessary data about the flight to carry to the details screen.
import 'package:airport_travel_app/model/flight.dart';

// Routes to the other screens.
// Route to the previous screen to re-enter a flight number, redo passport or find the button to log out.
import 'package:airport_travel_app/screen/number.dart';
// Route to the next screen to view flight and priority status.
import 'package:airport_travel_app/screen/detail.dart';

// This class is the configuration for the state. It holds the values (in this
// case the title and flight) provided by the parent (in this case the App widget) and
// used by the build method of the State. Fields in a Widget subclass are
// always marked "final".
class TicketPage extends StatefulWidget {
  const TicketPage({
    super.key,
    required this.passport,
    required this.flight
  });

  final File passport;
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

  // Load the page including a previously selected image path if there is one found and an ad instance for the page.
  @override
  void initState() {
    super.initState();
    loadTicketImage();
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
  Future<void> loadTicketImage() async {
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

  @override
  void dispose() {
    super.dispose();
  }

  // Navigate to the third or Flight Number entry page.
  void _numberPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => NumberPage(passport: widget.passport),
      )
    );
  }

  // Navigate past this last step and access the main HUD of the app with all of the information.
  void _detailPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPage(passport: widget.passport, flight: widget.flight, ticket: ticketImage!),
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
                            // Back button to return to Flight Number selection.
                            IconButton(
                              onPressed: _numberPage,
                              icon: const Icon(Icons.arrow_back),
                              color: Colors.white,
                              iconSize: 50,
                            ),
                          ],
                        ),
                        const SizedBox(height: 35),
                        const Icon(
                            Icons.airplane_ticket_outlined,
                            color: Colors.white,
                            size: 75,
                        ),
                        const SizedBox(height: 15),                        
                        // Main layout of the screen. 
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Headings conveying step number, a welcoming message, and instructions for this step.
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
                                  fontSize: 25,
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
                              // Ticket selection and display area.
                              GestureDetector(
                                onTap: pickAndSaveImage,
                                child: ticketImage != null
                                ? Column(
                                    children: [                                    
                                      Image.file(
                                        ticketImage!,
                                        width: 275,
                                        height: 128,
                                        fit: BoxFit.cover,
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [                                    
                                      DottedBorder(
                                        color: Colors.white,
                                        child: const SizedBox(
                                          height: 128,
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
                              // Bottom row of icons, with delete ticket and next step.
                              // There must be a ticket entry for the ability to delete it or move forward.
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
                                    onPressed: _detailPage,
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