import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'Theme.dart';
import 'DatabaseState.dart';
import 'WebsiteSelectionPage.dart';

void main() => runApp(MyApp());

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

