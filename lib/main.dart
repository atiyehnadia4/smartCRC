import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:smart_crc_gf/crc/crc_list.dart';
import 'package:smart_crc_gf/crc/crc_stack.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SmartCRC());
}

class SmartCRC extends StatelessWidget {
  const SmartCRC({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MaterialApp(
      title: 'SmartCRC',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const IntroductionPage(),
    );
  }
}

class IntroductionPage extends StatefulWidget {
  const IntroductionPage({Key key,}) : super(key: key);

  @override
  State<IntroductionPage> createState() => _IntroductionPage();
}

class _IntroductionPage extends State<IntroductionPage> {
  var page1 = PageViewModel(
    title: "Welcome to SmartCRC!",
    body:
    "Where your ideas take off! Design, Develop, and Launch your great ideas with the tool that aids in Object Oriented Designs",
    image: Padding(
      padding: EdgeInsets.only(top: 120.00),
      child: Image.asset(
        'assets/image/image1.png',
        height: 300.0,
      ),
    ),
  );

  var page2 = PageViewModel(
    title: "What is SmartCRC?",
    body:
    "SmartCRC is a mobile app that will support the development and usage of CRC Cards.",
    image: Padding(
      padding: EdgeInsets.only(top: 120.0),
      child: Center(
          child: Image.asset(
            'assets/image/image2.png',
            height: 300.0,
          )),
    ),
  );

  var page3 = PageViewModel(
    title: "What are CRC Cards?",
    body:
    "CRC Cards stand for Class, Responsibility, and Collaboration Cards that aid in object-oriented design.",
    image: Padding(
      padding: EdgeInsets.only(top: 120.0),
      child: Center(
          child: Image.asset(
            'assets/image/image3.png',
            height: 300.0,
          )),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      pages: [page1, page2, page3],
      onDone: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return const CRCStack();
        }));
      },
      showSkipButton: true,
      showNextButton: false,
      next: const Icon(Icons.navigate_next),
      skip: const Icon(Icons.skip_next),
      done: const Text("Done", style: TextStyle(fontWeight: FontWeight.w600)),
      dotsDecorator: DotsDecorator(
          size: const Size.square(10.0),
          activeSize: const Size(20.0, 10.0),
          color: Colors.black,
          spacing: const EdgeInsets.symmetric(horizontal: 3.0),
          activeShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25.0))),
    );
  }
}
