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

//  set websites(List<Map<String, dynamic>> value) {
//    _websites = value;
//    notifyListeners();
//  }

  List<Map<String, dynamic>> get documents => _documents;

//  set documents(List<Map<String, dynamic>> value) {
//    _documents = value;
//    notifyListeners();
//  }

  Map<String, dynamic> websiteIdToWebsite(int websiteId) {
    return websites.singleWhere((website) => website['id'] == websiteId);
  }

  List<Map<String, dynamic>> websiteIdToDocuments(int websiteId) {
    return documents
        .where((document) => document['websiteId'] == websiteId)
        .toList();
  }

  Map<String, dynamic> documentIdToDocument(int documentId) {
    return documents.singleWhere((document) => document['id'] == documentId);
  }

  int urlToDocumentId(String url) {
    return documents.singleWhere((document) => document['url'] == url,
        orElse: () => {'id': null})['id'];
  }

  // The real functions start here

  DatabaseState(context) {
    openDatabase(context);
  }

  Future<void> _loadFromDatabase() async {
    _websites = await database.query('websites');
    _documents = await database.query('documents',
        orderBy: 'pinned DESC, orderOnWebsite ASC');
    notifyListeners();
  }

  Future<sqflite.Database> openDatabase(context) {
    return Future(() async {
      database = await sqflite.openDatabase('exercise_sheets.db', version: 1,
          onCreate: (sqflite.Database db, int version) async {
        await db.execute('CREATE TABLE websites ('
            'id INTEGER PRIMARY KEY, '
            'title TEXT, '
            'url TEXT, '
            'maximumPoints DOUBLE, '
            'username TEXT, '
            'password TEXT, '
            'showArchived BOOLEAN'
            ')');
        await db.insert('websites', {
          'title': 'GeoTopo',
          'url': 'https://www.math.uni-bonn.de/people/ursula/courses.html',
          'maximumPoints': 50,
          'showArchived': 0,
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
            'maximumPoints DOUBLE'
            ')');
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
          // TODO: Store default values for a document in a final variable
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
          updatesBatch.update('documents', document, where: 'id = $documentId');
          print('Updated');
        }
      }

      String urlList = documentsOnWebsite
          .map((document) => '"${document['url']}"')
          .join(', ');

      updatesBatch.rawDelete('DELETE FROM documents '
          'WHERE websiteId = $websiteId AND url NOT IN ($urlList)');

      await updatesBatch.commit(noResult: true);

      await _loadFromDatabase();
    });
  }

  Future<void> setDocument(Map<String, dynamic> document) async {
    await database.update('documents', document,
        where: 'id = ${document['id']}');
    await _loadFromDatabase();
  }

  Future<void> setWebsite(Map<String, dynamic> website) async {
    await database.update('websites', website, where: 'id = ${website['id']}');
    await _loadFromDatabase();
  }
}
