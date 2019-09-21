import 'package:exercise_sheets/NetworkOperations.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

class DatabaseState with ChangeNotifier {
  // The states stored by the database
  sqflite.Database database;
  bool databaseError = false;
  List<Map<String, dynamic>> _websites = [];
  List<Map<String, dynamic>> _documents = [];

  List<Map<String, dynamic>> get websites => _websites;

  set websites(List<Map<String, dynamic>> value) {
    _websites = value;
    notifyListeners();
  }

  Map<String, dynamic> websiteIdToWebsite(int websiteId) {
    return websites.firstWhere((website) => website['id'] == websiteId);
  }

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

  // The real functions start here

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
            'CREATE TABLE documents (id INTEGER PRIMARY KEY, website_id INTEGER, url TEXT, title TEXT, titleOnWebsite TEXT, statusCodeReason TEXT, lastModified TEXT, orderOnWebsite INT, pinned BOOLEAN, points DOUBLE, maximumPoints DOUBLE)');
        await db.insert('documents', {
          'website_id': 1,
          'url': 'http://www.math.uni-bonn.de/people/ursula/uebungss1912.pdf',
          'title': 'Übungsblatt 12',
          'titleOnWebsite': 'Übungsblatt 12',
          'statusCodeReason': 'OK',
          'lastModified': '2019-04-02 15:19:15.000',
          'orderOnWebsite': 1,
          'pinned': 0,
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

  Future<void> updateDocumentMetadata(int websiteId) {
    Map<String, dynamic> website = websiteIdToWebsite(websiteId);
    return NetworkOperations.retrieveDocumentMetadata(
            website['url'], website['username'], website['password'])
        .then((List<Map<String, dynamic>> values) {
      // TODO: Update the SQLite database
    });
  }
}
