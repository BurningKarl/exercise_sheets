import 'package:flutter/material.dart';

final ThemeData exerciseSheetsTheme = ThemeData(
    // This is the theme of the application.
    primarySwatch: Colors.blue,
    cardTheme: CardTheme(
        margin: EdgeInsets.all(7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(7)),
        )
    )
);
