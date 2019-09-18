import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'Theme.dart';
import 'DatabaseBuilder.dart';
import 'WebsiteSelectionPage.dart';

void main() => runApp(MyApp());

// TODO: A provider for websites and a provider for documents is needed as well
// There is no need for the database provider to provide a future

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Provider<Future<sqflite.Database>>(
      builder: DatabaseBuilder.openDatabase,
      child: MaterialApp(
        title: 'Exercise Sheets',
        theme: exerciseSheetsTheme,
        home: WebsiteSelectionPage(),
      )
    );
  }
}

