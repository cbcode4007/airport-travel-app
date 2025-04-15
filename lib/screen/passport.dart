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
  String fileUploadStatus = 'Upload your passport to display here.';
  // Initialize the background colour which changes at certain times.
  Color? _color = Colors.red[400];
  // Initialize the timer for constant updating of the program.
  late Timer _clockTimer;
  // Declare to-be image file for the user passport.
  File? _passportImage;

  @override
  void initState() {
    super.initState();
    _startClock();
    _updateTime();
    _loadPassportImage();
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
    // Calculate time until flight.
    Duration difference = departDate.difference(DateTime.now());

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
        fileUploadStatus = 'Passport uploaded. Tap to replace.';
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
      fileUploadStatus = 'Passport uploaded. Tap to replace.';
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
      fileUploadStatus = 'Upload your passport to display here.';
    });
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Passport Image'),
        content: const Text('Are you sure you want to delete this image?'),
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          verticalDirection: VerticalDirection.down,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: _timer,
                  icon: const Icon(Icons.arrow_back),
                  color: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 25),
            Text(
              fileUploadStatus,
              style: GoogleFonts.openSans(color: Colors.white, fontSize: 15),
            ),
            const SizedBox(height: 25),
            GestureDetector(
              onTap: _pickAndSaveImage,
              child: _passportImage != null
                  ? Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _passportImage!,
                          width: 275,
                          height: 385,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 25),
                      IconButton(
                        onPressed: _confirmDelete,
                        icon: const Icon(Icons.delete, color: Colors.white),
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
                            child: Icon(Icons.file_upload_outlined, color: Colors.white, size: 50)
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}