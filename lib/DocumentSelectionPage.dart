import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';

import 'DatabaseState.dart';
import 'NetworkOperations.dart';
import 'WebsiteInfoPage.dart';
import 'DocumentInfoPage.dart';

enum DocumentSelectionPageActions { show_hide_archived }

class DocumentSelectionPage extends StatefulWidget {
  final int websiteId;

  const DocumentSelectionPage(this.websiteId);

  @override
  State<StatefulWidget> createState() => DocumentSelectionPageState(websiteId);
}

class DocumentSelectionPageState extends State<DocumentSelectionPage> {
  final int websiteId;
  final NumberFormat pointsFormat = NumberFormat.decimalPattern();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  bool updatePdfsOnRefresh = false;

  // TODO: Add multi selection of documents analogous to WebsiteSelectionPage

  DocumentSelectionPageState(this.websiteId);

  String pointsToString(double value) {
    return value != null ? pointsFormat.format(value) : null;
  }

  int negate(int value) {
    if (value == 0) {
      return 1;
    } else {
      return 0;
    }
  }

  void showSnackBar(String content) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(content),
    ));
  }

  bool isPdfUpdateNecessary(DatabaseState databaseState) {
    return databaseState
        .websiteIdToDocuments(websiteId)
        .any(databaseState.isPdfUpdateNecessary);
  }

  void handleNetworkError(dynamic error, BuildContext context) {
    print('Network error: $error');
    String errorText;
    if (error is DioError && error.type == DioErrorType.DEFAULT) {
      errorText = 'No network connection available';
    } else {
      errorText = 'A network error occured: \n$error';
    }
    showSnackBar(errorText);
  }

  Future<void> handleRefresh(DatabaseState databaseState) async {
    print('handleRefresh: updatePdfsOnRefresh=$updatePdfsOnRefresh');
    if (!updatePdfsOnRefresh) {
      await databaseState
          .updateDocumentMetadata(websiteId)
          .then((numberOfUpdates) {
        showSnackBar('Successfully scanned the website and updated '
            '$numberOfUpdates documents');
      }).catchError((error) => handleNetworkError(error, context));
    } else if (isPdfUpdateNecessary(databaseState)) {
      databaseState.updateDocumentPdfs(websiteId).then((numberOfUpdates) {
        showSnackBar('Successfully updated $numberOfUpdates PDFs');
      }).catchError((error) => handleNetworkError(error, context));
    } else {
      databaseState
          .updateDocumentPdfs(websiteId, forceUpdate: true)
          .then((numberOfUpdates) {
        showSnackBar('Successfully updated $numberOfUpdates PDFs');
      }).catchError((error) => handleNetworkError(error, context));
    }
    updatePdfsOnRefresh = false;
  }

  Widget buildDocumentItem(BuildContext context, Map<String, dynamic> document,
      DatabaseState databaseState, bool showArchived) {
    var leadingIconSymbol;
    if (document['statusMessage'] != 'OK') {
      leadingIconSymbol = Icons.cancel;
    } else if (document['archived'] != 0) {
      leadingIconSymbol = Icons.archive;
    } else if (document['pinned'] != 0) {
      leadingIconSymbol = Icons.star;
    } else if (document['points'] != null) {
      leadingIconSymbol = Icons.assignment_turned_in;
    } else {
      leadingIconSymbol = Icons.assignment;
    }

    String pointsText = document['points'] != null
        ? 'Points: ${pointsToString(document['points'])}'
            '/${pointsToString(document['maximumPoints'])}'
        : null;

    Widget item = Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: Icon(
              leadingIconSymbol,
              color: document['file'] != null ? Colors.green : null,
            ),
            title: Text(document['title']),
            subtitle: pointsText != null ? Text(pointsText) : null,
            trailing: IconButton(
              icon: Icon(Icons.info),
              onPressed: () {
                print('Opened info for document ${document['title']} '
                    'with id ${document['id']}');
                Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => DocumentInfoPage(document['id']),
                    ));
              },
            ),
            onTap: () async {
              print('Tried to open document ${document['title']} '
                  'with id ${document['id']}');
              if (document['file'] != null) {
                print('Opened locally');
                await OpenFile.open(document['file']);
              } else if (document['statusMessage'] == 'OK') {
                print('Opened by url');
                NetworkOperations.launchUrl(document['url']);
              } else {
                print('Not opened: ${document['statusMessage']}');
                showSnackBar('This document is unreachable: ' +
                    document['statusMessage']);
              }
            },
          ),
        ],
      ),
    );

    if (showArchived) {
      return item;
    } else {
      return Dismissible(
        key: Key(document['id'].toString()),
        direction: DismissDirection.horizontal,
        onDismissed: (DismissDirection direction) async {
          // Archive this document
          Map<String, dynamic> alteredDocument = Map.from(document);
          alteredDocument['archived'] = negate(document['archived']);
          await databaseState.setDocument(alteredDocument);
          print('Archived website ${document['title']} '
              'with id ${document['id']}');
        },
        background: Container(
          color: Colors.blue,
          child: Icon(Icons.archive),
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        ),
        secondaryBackground: Container(
          color: Colors.blue,
          child: Icon(Icons.archive),
          alignment: Alignment.centerRight,
          padding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        ),
        child: item,
      );
    }
  }

  Widget buildContent(BuildContext context, DatabaseState databaseState) {
    Map<String, dynamic> website = databaseState.websiteIdToWebsite(websiteId);
    List<Map<String, dynamic>> documents =
        databaseState.websiteIdToDocuments(websiteId);
    if (website['showArchived'] == 0) {
      // Show only those document that are not archived
      documents.retainWhere((document) => document['archived'] == 0);
    }
    if (databaseState.databaseError) {
      return Center(
        child: Text('The database could not be opened'),
      );
    }
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: () => handleRefresh(databaseState),
      child: Scrollbar(
        child: ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, int index) => buildDocumentItem(context,
                documents[index], databaseState, website['showArchived'] != 0)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseState>(builder: (context, databaseState, _) {
      Map<String, dynamic> website =
          databaseState.websiteIdToWebsite(websiteId);

      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(website['title']),
          actions: <Widget>[
            IconButton(
              icon: Icon(isPdfUpdateNecessary(databaseState)
                  ? Icons.cloud_download
                  : Icons.cloud_done),
              tooltip: 'Download PDFs',
              onPressed: () async {
                updatePdfsOnRefresh = true;
                await _refreshIndicatorKey.currentState.show();
              },
            ),
            IconButton(
              icon: Icon(Icons.settings),
              tooltip: 'Settings',
              onPressed: () {
                print('Opened settings for website ${website['title']} '
                    'with id ${website['id']}');

                Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => WebsiteInfoPage(websiteId),
                    ));
              },
            ),
            PopupMenuButton<DocumentSelectionPageActions>(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: DocumentSelectionPageActions.show_hide_archived,
                  child: Text(website['showArchived'] == 0
                      ? 'Show archived documents'
                      : 'Hide archived documents'),
                )
              ],
              onSelected: (DocumentSelectionPageActions value) {
                if (value == DocumentSelectionPageActions.show_hide_archived) {
                  Map<String, dynamic> alteredWebsite = Map.from(website);
                  alteredWebsite['showArchived'] =
                      negate(alteredWebsite['showArchived']);
                  databaseState.setWebsite(alteredWebsite);
                }
              },
            )
          ],
        ),
        body: buildContent(context, databaseState),
      );
    });
  }
}
