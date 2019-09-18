import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'Theme.dart';
import 'WebsiteSelectionPage.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exercise Sheets',
      theme: exerciseSheetsTheme,
      home: WebsiteSelectionPage(),
    );
  }
}

