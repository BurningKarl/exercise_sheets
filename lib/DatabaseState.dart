import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

class DatabaseState with ChangeNotifier {
  sqflite.Database database;
  List<Map<String, dynamic>> _websites = [];
  List<Map<String, dynamic>> _documents = [];


  DatabaseState(context) {
    openDatabase(context);
  }

  Future<sqflite.Database> openDatabase(context) {
    return Future(() async {
      database = await sqflite.openDatabase('exercise_sheets.db', version: 1,
          onCreate: (sqflite.Database db, int version) async {
        await db.execute(
            'CREATE TABLE websites (id INTEGER PRIMARY KEY, name TEXT, url TEXT, maximumPoints INTEGER, username TEXT, password TEXT)');
        await db.insert('websites', {
          'name': 'GeoTopo',
          'url': 'https://www.math.uni-bonn.de/people/ursula/courses.html',
          'maximumPoints': 50
        });
      });

      _websites = await database.query('websites');
      _documents = await database.query('documents');
      notifyListeners();

      return database;
    }).catchError((error) {
      // TODO: Show a SnackBar
    });
  }

  List<Map<String, dynamic>> get websites => _websites;

  set websites(List<Map<String, dynamic>> value) {
    _websites = value;
    notifyListeners();

  }

  List<Map<String, dynamic>> get documents => _documents;

  set documents(List<Map<String, dynamic>> value) {
    _documents = value;
    notifyListeners();
  }
}
