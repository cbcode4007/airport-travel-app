import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class TimerPage extends StatefulWidget {
  const TimerPage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  String errorMessage = '';
  final double fontSizeHeading = 27;
  final double fontSizeBody = 15;
  final TextEditingController _controller = TextEditingController();
  final flightNumberRegExp = RegExp(r'^[a-zA-Z]{2,3}\d{1,4}$');

  void _callFlightAPI (String flightNumber) async {
    String errorMessageCall = 'The flight number you entered could not be found! Please check and try again.';

    const key = 'c1a9697f9b6263fffcb12a94543e68fa';
    const url = 'https://api.aviationstack.com/v1/flights?access_key=$key';
    final uri = Uri.parse(url);
    final response = await http.get(uri);
    final body = response.body;
    final json = jsonDecode(body);
    
    if(json.toString().contains((flightNumber))) {
      
    }
    else {
      errorMessage = errorMessageCall;
      _spawnErrorMessage(errorMessage);
    }
  }

  void _validateFlightInput (String flightNumber) {
    String errorMessageEmpty = 'You must enter a flight number to continue!';
    String errorMessageFormat = 'The flight number you entered is invalid! Please use two or three letters at the front and one to four numbers behind them.';

    setState(() {
      errorMessage = '';
    });

    if (flightNumber != '') {
      if ((flightNumber.length > 1 && flightNumber.length < 7) && (flightNumberRegExp.hasMatch(flightNumber))) {
        _callFlightAPI(flightNumber);
        if (errorMessage == '') {
          Navigator.pushNamed(context, '/timer');
        }
      }
      else {
        errorMessage = errorMessageFormat;
        _spawnErrorMessage(errorMessage);
      }
    }
    else {
      errorMessage = errorMessageEmpty;
      _spawnErrorMessage(errorMessage);
    }
  }

  void _spawnErrorMessage (String error) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.all(8),
          height: 90,
          decoration: const BoxDecoration(
            color: Color(0xFFC72C41),
            borderRadius: BorderRadius.all(Radius.circular(20))
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "An error has occurred!",
                style: TextStyle(fontSize: 17, color: Colors.white)
              ),
              Text(
                error,
                style: const TextStyle(fontSize: 11, color: Colors.white)
              ),
            ],
          ),
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      // appBar: AppBar(
      //   // TRY THIS: Try changing the color here to a specific color (to
      //   // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
      //   // change color while the other colors stay the same.
      //   backgroundColor: Colors.amber,
      //   // Here we take the value from the MyHomePage object that was created by
      //   // the App.build method, and use it to set our appbar title.
      //   title: Text(widget.title),
      // ),
      backgroundColor: Colors.redAccent,  
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
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.          
          mainAxisAlignment: MainAxisAlignment.center, 
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(100.0),
              child: Container(
                height: 100,
                width: 100,
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                  image: DecorationImage(
                    image: AssetImage('assets/images/logo.png')
                  )
                )                  
              )
            ),
            SizedBox(
              height: 70,
              child: Text(
                'Welcome!',
                style: GoogleFonts.openSans(color:Colors.white, fontWeight: FontWeight.bold, fontSize: fontSizeHeading)
              )          
            ), 
            Column(
              children: [
                Text(
                  'Please enter your flight number below.',
                  style: GoogleFonts.openSans(color: Colors.white, fontSize: fontSizeBody)
                ),
                Container(
                  margin: const EdgeInsets.all(20.0),
                  child: SizedBox(
                    width: 280,
                    child: TextField(
                      controller: _controller,
                      style: GoogleFonts.openSans(color: Colors.white, fontSize: fontSizeBody),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white70)
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white)
                        ),
                        hintText: 'e.g. AA1, AA11, AA111, AA1111',
                        hintStyle: GoogleFonts.openSans(color: Colors.white70, fontSize: fontSizeBody)
                      ),
                    ),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {                
                _validateFlightInput(_controller.text);
                _controller.clear();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                fixedSize: const Size(150, 40)
              ),
              child: Text(
                'SUBMIT',
                style: GoogleFonts.openSans(
                fontSize: fontSizeBody,
                fontWeight: FontWeight.bold,
                color: Colors.lightBlue,
                ),
              ),
            ),
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _incrementCounter,
      //   tooltip: 'Submit the entered flight number',
      //   child: Text(
      //         'SUBMIT',
      //         style: GoogleFonts.openSans(color: Colors.lightBlue, fontWeight: FontWeight.bold)
      //       ),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}