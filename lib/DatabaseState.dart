import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

class DatabaseState with ChangeNotifier {
  bool databaseError = false;
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
            'CREATE TABLE websites (id INTEGER PRIMARY KEY, name TEXT, url TEXT, maximumPoints DOUBLE, username TEXT, password TEXT)');
        await db.insert('websites', {
          'name': 'GeoTopo',
          'url': 'https://www.math.uni-bonn.de/people/ursula/courses.html',
          'maximumPoints': 50
        });
        await db.execute(
            'CREATE TABLE documents (id INTEGER PRIMARY KEY, website_id INTEGER, name TEXT, url TEXT, points DOUBLE, maximumPoints DOUBLE)');
        await db.insert('documents', {
          'website_id': 1,
          'name': 'Übungsblatt 12',
          'url': 'http://www.math.uni-bonn.de/people/ursula/uebungss1912.pdf',
          'points': 20,
          'maximumPoints': 50,
        });
      });

      _websites = await database.query('websites');
      _documents = await database.query('documents');
      notifyListeners();

      return database;
    }).catchError((error) {
      databaseError = true;
      notifyListeners();
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
