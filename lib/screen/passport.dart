// Future class for asynchronous updating.
import 'dart:async';
// Route to the previous screen.
import 'package:airport_travel_app/screen/timer.dart';
// Flight data to determine background colour.
import 'package:airport_travel_app/model/flight.dart';
// Material app design, or in other words Google recommendations for UI.
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
// Timezone logic for correct displays.
import 'package:timezone/timezone.dart' as tz;
// Dynamic advertisement banners.
import 'package:google_mobile_ads/google_mobile_ads.dart';

// This class is the configuration for the state. It holds the values (in this
// case the title) provided by the parent (in this case the App widget) and
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

    setState(() {
      if (difference.inMinutes < 90)  {
        _color = Colors.amberAccent[700];
      }
      if (difference.inMinutes < 45) {
        _color = Colors.greenAccent[700];
      }
      if (difference.inMinutes < 1 && difference.inSeconds < 1) {
        _color = Colors.black;
        difference = const Duration(hours: 0, minutes: 0, seconds: 0);
      }
    });
  }

  void loadAd() async {
    // Try to initialize an ad unit to be displayed in ad widgets.
    // Only initialize ads on supported platforms.
    if (Platform.isAndroid || Platform.isIOS) {
      // final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      //   MediaQuery.sizeOf(context).width.truncate());
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

  void _timer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TimerPage(title: 'timer', flight: widget.flight,),
      )
    );
  }

  Future<void> _loadPassportImage() async {
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

  Future<void> _pickAndSaveImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final newPath = '${appDir.path}/${image.name}';
    final newImage = await File(image.path).copy(newPath);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('passport_image_path', newPath);

    setState(() {
      _passportImage = newImage;
      fileUploadStatus = yesUpload;
    });
  }

  Future<void> _deleteImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('passport_image_path');

    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      await prefs.remove('passport_image_path');
    }

    setState(() {
      _passportImage = null;
      fileUploadStatus = noUpload;
    });
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _color,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                // Main scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top icon
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
                        Text(
                          fileUploadStatus,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.openSans(color: Colors.white, fontSize: 15),
                        ),
                        const SizedBox(height: 25),

                        // Upload zone or preview
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

                // Ad pinned to bottom
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