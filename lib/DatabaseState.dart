import 'dart:convert';
import 'dart:io';
import 'package:exercise_sheets/NetworkOperations.dart';
import 'package:exercise_sheets/StorageOperations.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

class DatabaseDefaults {
  static const Map<String, dynamic> defaultWebsite = {
    'title': 'New website',
    'url': null,
    'maximumPoints': 50.0,
    'username': '',
    'password': '',
    'showArchived': 0,
  };

  static const Map<String, dynamic> defaultDocument = {
    'websiteId': null,
    'url': null,
    'title': 'Default document',
    'titleOnWebsite': 'Default document',
    'statusMessage': 'Bad Request',
    'lastModified': '1970-01-01 00:00:00.000Z',
    'file': null,
    'filelastModified': null,
    'orderOnWebsite': 0,
    'archived': 0,
    'pinned': 0,
    'points': null,
    'maximumPoints': null,
  };

  static Map<String, dynamic> completeWebsite(
      Map<String, dynamic> incompleteWebsite,
      {Map<String, dynamic> defaults}) {
    return Map.from(defaultWebsite)
      ..addAll(defaults ?? {})
      ..addAll(incompleteWebsite);
  }

  static Map<String, dynamic> completeDocument(
      Map<String, dynamic> incompleteDocument,
      {Map<String, dynamic> defaults}) {
    return Map.from(defaultDocument)
      ..addAll(defaults ?? {})
      ..addAll(incompleteDocument);
  }
}

class DatabaseState with ChangeNotifier {
  // The states stored by the database
  sqflite.Database database;
  bool databaseError = false;
  List<Map<String, dynamic>> _websites = [];
  List<Map<String, dynamic>> _documents = [];
  bool showArchivedDocuments = false;

  List<Map<String, dynamic>> get websites => _websites;

  List<Map<String, dynamic>> get documents => _documents;

  Map<String, dynamic> websiteIdToWebsite(int websiteId) {
    if (websiteId == null) return DatabaseDefaults.defaultWebsite;
    return websites.singleWhere((website) => website['id'] == websiteId);
  }

  List<Map<String, dynamic>> websiteIdToDocuments(int websiteId) {
    return documents
        .where((document) => document['websiteId'] == websiteId)
        .toList();
  }

  Map<String, double> websiteIdToStatistics(int websiteId) {
    double achievedTotal = 0;
    double maximumTotal = 0;
    websiteIdToDocuments(websiteId)
        .where((document) => document['points'] != null)
        .forEach((document) {
      achievedTotal += document['points'];
      maximumTotal += document['maximumPoints'];
    });
    return {
      'achieved': achievedTotal,
      'maximum': maximumTotal,
    };
  }

  Map<String, dynamic> documentIdToDocument(int documentId) {
    if (documentId == null) return DatabaseDefaults.defaultDocument;
    return documents.singleWhere((document) => document['id'] == documentId);
  }

  int urlToDocumentId(String url, int websiteId) {
    return documents.singleWhere(
        (document) =>
            document['url'] == url && document['websiteId'] == websiteId,
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

  Future<void> updateDocument(int documentId, Map<String, dynamic> update) async {
    await database.update('documents', update, where: 'id = $documentId');
    await _loadFromDatabase();
  }

  Future<void> updateWebsite(int websiteId, Map<String, dynamic> update) async {
    if (websiteId == null) {
      await database.insert('websites', update);
    } else {
      await database.update('websites', update, where: 'id = $websiteId');
    }
    await _loadFromDatabase();
  }

  Future<void> _saveDocumentUpdatesToDatabase(
      Iterable<Map<String, dynamic>> documentUpdates) async {
    sqflite.Batch updatesBatch = database.batch();

    for (Map<String, dynamic> document in documentUpdates) {
      if (document['id'] == null) {
        updatesBatch.insert('documents', document);
      } else {
        updatesBatch.update('documents', document,
            where: 'id = ${document['id']}');
      }
    }

    await updatesBatch.commit(noResult: true);
    await _loadFromDatabase();
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
            'statusMessage TEXT, '
            'lastModified TEXT, '
            'file TEXT, '
            'fileLastModified TEXT, '
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
          'statusMessage': 'OK',
          'lastModified': '2019-04-02 15:19:15.000',
          'file': null,
          'fileLastModified': null,
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

  Future<int> updateDocumentMetadata(int websiteId) async {
    Map<String, dynamic> website = websiteIdToWebsite(websiteId);
    NetworkOperations operations = NetworkOperations.withAuthentication(
        website['username'], website['password']);

    Iterable<Map<String, dynamic>> documentUpdates =
        await operations.retrieveDocumentMetadata(website['url']);

    String urlList =
        documentUpdates.map((document) => '"${document['url']}"').join(', ');

    documentUpdates = documentUpdates.map((Map<String, dynamic> document) {
      int documentId = urlToDocumentId(document['url'], websiteId);
      if (documentId == null) {
        // New document
        return DatabaseDefaults.completeDocument(document, defaults: {
          'websiteId': websiteId,
          'title': document['titleOnWebsite'],
          'maximumPoints': website['maximumPoints'],
        });
      } else {
        document['id'] = documentId;
        return document;
      }
    });

    await database.rawDelete('DELETE FROM documents '
        'WHERE websiteId = $websiteId AND url NOT IN ($urlList)');

    await _saveDocumentUpdatesToDatabase(documentUpdates);

    return documentUpdates.length;
  }

  bool isPdfUpdateNecessary(Map<String, dynamic> document) {
    if (document['statusMessage'] != 'OK') {
      return false; // The document is unreachable, no download needed
    } else if (document['file'] == null) {
      return true; // No local PDF, download needed
    } else if (document['lastModified'] == null) {
      return true; // No info when it was last modified, update needed
    } else {
      // An update is needed iff the file is older than the document online
      var onlineLastModified = DateTime.parse(document['lastModified']);
      var fileLastModified = DateTime.parse(document['fileLastModified']);
      return fileLastModified.isBefore(onlineLastModified);
    }
  }

  Future<int> updateDocumentPdfs(int websiteId,
      {bool forceUpdate = false}) async {
    Map<String, dynamic> website = websiteIdToWebsite(websiteId);
    NetworkOperations operations = NetworkOperations.withAuthentication(
        website['username'], website['password']);

    DateTime now = DateTime.now().toUtc();
    Map<int, File> files = Map.fromEntries(await Future.wait(
        websiteIdToDocuments(websiteId)
            .where(forceUpdate ? (_) => true : isPdfUpdateNecessary)
            .map(operations.downloadDocumentPdf)));

    Iterable<Map<String, dynamic>> documentUpdates = files.entries.map(
      (entry) => {
        'id': entry.key,
        'file': entry.value.path,
        'fileLastModified': now.toString(),
      },
    );

    await _saveDocumentUpdatesToDatabase(documentUpdates);

    return documentUpdates.length;
  }

  Future<void> deleteWebsites(Iterable<int> websiteIds) async {
    sqflite.Batch batch = database.batch();
    for (int websiteId in websiteIds) {
      (await StorageOperations.websiteIdToPdfDirectory(websiteId))
          .delete(recursive: true)
          .catchError((_) {});
      batch.delete('websites', where: 'id = $websiteId');
      batch.delete('documents', where: 'websiteId = $websiteId');
    }
    await batch.commit(noResult: true);
    await _loadFromDatabase();
  }

  String toJson() {
    return jsonEncode({
      'websites': websites,
      'documents': documents,
    });
  }

  Future<void> exportToFile(File file) async {
    await file.create(recursive: true);
    await file.writeAsString(toJson());
  }

  Future<void> importFromFile(File file) async {
    Map<String, dynamic> content = jsonDecode(await file.readAsString());

    Map<int, int> oldToNewId = Map();

    for (Map<String, dynamic> website in content['websites']) {
      oldToNewId[website['id']] =
          await database.insert('websites', website..remove('id'));
    }

    sqflite.Batch batch = database.batch();
    for (Map<String, dynamic> document in content['documents']) {
      document.addAll({
        'id': null,
        'websiteId': oldToNewId[document['websiteId']],
        'file': null,
        'fileLastModified': null,
      });

      batch.insert('documents', DatabaseDefaults.completeDocument(document));
    }

    await batch.commit(noResult: true);

    await _loadFromDatabase();
  }
}
