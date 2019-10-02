import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

import 'DatabaseState.dart';
import 'NetworkOperations.dart';
import 'WebsiteInfoPage.dart';
import 'DocumentInfoPage.dart';

enum DocumentSelectionPageActions { show_hide_archived }

class DocumentSelectionPage extends StatelessWidget {
  final int websiteId;

  const DocumentSelectionPage(this.websiteId);

  int negate(int value) {
    if (value == 0) {
      return 1;
    } else {
      return 0;
    }
  }

  String pointsToText(double points) {
    if (points % 1 == 0) {
      return points.toStringAsFixed(0);
    } else {
      return points.toStringAsFixed(2);
    }
  }

  Card buildDocumentCard(BuildContext context, Map<String, dynamic> document) {
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
        ? 'Points: ${pointsToText(document['points'])}'
            '/${pointsToText(document['maximumPoints'])}'
        : '';

    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: Icon(leadingIconSymbol),
            title: Text(document['title']),
            subtitle: Text(pointsText),
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
              // TODO: Open the local PDF document if possible
              if (document['file'] != null) {
                NetworkOperations.launchUrl(
                    Uri.file(document['file']).toString());
              } else if (document['statusMessage'] == 'OK') {
                NetworkOperations.launchUrl(document['url']);
              } else {
                Scaffold.of(context).showSnackBar(SnackBar(
                  content: Text('This document is unreachable: ' +
                      document['statusMessage']),
                ));
              }
            },
          ),
        ],
      ),
    );
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
      onRefresh: () {
        return databaseState.updateDocumentMetadata(websiteId).catchError(
            (error) {
          Scaffold.of(context).showSnackBar(SnackBar(
            content: Text('A network error occured: \n$error'),
          ));
        }, test: (error) => error is IOException).catchError((error) {
          Scaffold.of(context).showSnackBar(SnackBar(
            content: Text('A network error occured: \n$error'),
          ));
        }, test: (error) => error is DioError);
      },
      child: Scrollbar(
        child: ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, int index) {
              return buildDocumentCard(context, documents[index]);
            }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseState>(builder: (context, databaseState, _) {
      Map<String, dynamic> website =
          databaseState.websiteIdToWebsite(websiteId);
      return Scaffold(
        appBar: AppBar(
          title: Text(website['title']),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.cloud_download),
              onPressed: () async {
                //TODO: Download all PDF files of the documents
                // The icon should change to Icons.cloud_done if none of
                // the lastModified is newer than the local files
                // Add columns: file and fileLastModified
              },
            ),
            IconButton(
              icon: Icon(Icons.settings),
              tooltip: 'Settings',
              onPressed: () async {
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
        body: Builder(
          // This is necessary to use Scaffold.of(innerContext)
          builder: (innerContext) => buildContent(innerContext, databaseState),
        ),
      );
    });
  }
}
