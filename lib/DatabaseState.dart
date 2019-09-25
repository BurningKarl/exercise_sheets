import 'package:exercise_sheets/NetworkOperations.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

class DatabaseState with ChangeNotifier {
  // The states stored by the database
  sqflite.Database database;
  bool databaseError = false;
  List<Map<String, dynamic>> _websites = [];
  List<Map<String, dynamic>> _documents = [];
  bool showArchivedDocuments = false;

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

  Map<String, dynamic> websiteIdToWebsite(int websiteId) {
    return websites.firstWhere((website) => website['id'] == websiteId);
  }

  List<Map<String, dynamic>> websiteIdToDocuments(int websiteId) {
    return documents
        .where((document) => document['websiteId'] == websiteId)
        .toList();
  }

  Map<String, dynamic> documentIdToDocument(int documentId) {
    return documents.firstWhere((document) => document['id'] == documentId);
  }

  int urlToDocumentId(String url) {
    return documents.firstWhere((document) => document['url'] == url,
        orElse: () => {'id': null})['id'];
  }

  // The real functions start here

  DatabaseState(context) {
    openDatabase(context);
  }

  Future<void> _loadFromDatabase() async {
    _websites = await database.query('websites');
    _documents = await database.query('documents',
        orderBy: 'pinned DESC, orderOnWebsite ASC', where: 'archived = 0');
    notifyListeners();
  }

  Future<sqflite.Database> openDatabase(context) {
    return Future(() async {
      database = await sqflite.openDatabase('exercise_sheets.db', version: 1,
          onCreate: (sqflite.Database db, int version) async {
        await db.execute('CREATE TABLE websites ('
            'id INTEGER PRIMARY KEY, '
            'name TEXT, '
            'url TEXT, '
            'maximumPoints DOUBLE, '
            'username TEXT, '
            'password TEXT)');
        await db.insert('websites', {
          'name': 'GeoTopo',
          'url': 'https://www.math.uni-bonn.de/people/ursula/courses.html',
          'maximumPoints': 50
        });
        await db.execute('CREATE TABLE documents ('
            'id INTEGER PRIMARY KEY, '
            'websiteId INTEGER, '
            'url TEXT, '
            'title TEXT, '
            'titleOnWebsite TEXT, '
            'statusCodeReason TEXT, '
            'lastModified TEXT, '
            'orderOnWebsite INT, '
            'archived BOOLEAN, '
            'pinned BOOLEAN, '
            'points DOUBLE, '
            'maximumPoints DOUBLE)');
        await db.insert('documents', {
          'websiteId': 1,
          'url': 'http://www.math.uni-bonn.de/people/ursula/uebungss1912.pdf',
          'title': 'Übungsblatt 12',
          'titleOnWebsite': 'Übungsblatt 12',
          'statusCodeReason': 'OK',
          'lastModified': '2019-04-02 15:19:15.000',
          'orderOnWebsite': 1,
          'archived': 0,
          'pinned': 0,
          'points': 20,
          'maximumPoints': 50,
        });
      });

      await _loadFromDatabase();

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
        .then((List<Map<String, dynamic>> documentsOnWebsite) async {
      sqflite.Batch updatesBatch = database.batch();
      for (Map<String, dynamic> document in documentsOnWebsite) {
        int documentId = urlToDocumentId(document['url']);
        if (documentId == null) {
          document.addAll({
            'websiteId': websiteId,
            'title': document['titleOnWebsite'],
            'archived': 0,
            'pinned': 0,
            'maximumPoints': website['maximumPoints'],
          });
          updatesBatch.insert('documents', document);
          print('Inserted');
        } else {
          updatesBatch.update('documents', document,
              where: 'id = ?', whereArgs: [documentId]);
          print('Updated');
        }
      }

      String urlList = documentsOnWebsite
          .map((document) => '"' + document['url'] + '"')
          .join(', ');

      updatesBatch.rawDelete('DELETE FROM documents ' +
          'WHERE websiteId = ' +
          websiteId.toString() +
          ' AND url NOT IN (' +
          urlList +
          ')');

      await updatesBatch.commit(noResult: true);

      _loadFromDatabase();
    });
  }
}
