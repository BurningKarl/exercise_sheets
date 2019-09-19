import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

class DatabaseState with ChangeNotifier {
  sqflite.Database database;
  bool databaseError = false;
  List<Map<String, dynamic>> _websites = [];
  Map<int, Map<String, dynamic>> _websiteIdToWebsite = Map();
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

      websites = await database.query('websites');
      documents = await database.query('documents');
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
    _websiteIdToWebsite.clear();
    for (Map<String, dynamic> website in websites) {
      _websiteIdToWebsite[website['id']] = website;
    }
    notifyListeners();
  }

  Map<int, Map<String, dynamic>> get websiteIdToWebsite => _websiteIdToWebsite;

  List<Map<String, dynamic>> get documents => _documents;

  set documents(List<Map<String, dynamic>> value) {
    _documents = value;
    notifyListeners();
  }

  List<Map<String, dynamic>> websiteIdToDocuments(int websiteId) {
    return documents
        .where((document) => document['website_id'] == websiteId)
        .toList();
  }
}
