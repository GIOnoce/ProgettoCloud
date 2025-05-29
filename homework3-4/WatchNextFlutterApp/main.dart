import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() => runApp(MyTEDxApp());

class MyTEDxApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyTEDx Rewind',
      theme: ThemeData(
        primarySwatch: Colors.red,
        fontFamily: 'Roboto',
      ),
      home: HomeScreen(),
    );
  }
}
