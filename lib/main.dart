import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'Theme.dart';
import 'DatabaseState.dart';
import 'WebsiteSelectionPage.dart';

void main() => runApp(MyApp());

// TODO: A provider for websites and a provider for documents is needed as well
// There is no need for the database provider to provide a future

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DatabaseState>(
      builder: (context) => DatabaseState(context),
      child: MaterialApp(
        title: 'Exercise Sheets',
        theme: exerciseSheetsTheme,
        home: WebsiteSelectionPage(),
      )
    );
  }
}

