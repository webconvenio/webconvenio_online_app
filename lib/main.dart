import 'package:flutter/material.dart';
import 'package:webconvenio_app/screens/splash_screen.dart';

void main() {
  runApp(WebconvenioOnlineApp());
}

class WebconvenioOnlineApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: SplashScreen());
  }
}
