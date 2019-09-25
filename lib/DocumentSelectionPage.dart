import 'dart:io';
import 'package:exercise_sheets/DocumentInfoPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'DatabaseState.dart';

class DocumentSelectionPage extends StatelessWidget {
  final int websiteId;

  const DocumentSelectionPage(this.websiteId);

  String pointsToText(double points) {
    if (points % 1 == 0) {
      return points.toStringAsFixed(0);
    } else {
      return points.toStringAsFixed(2);
    }
  }

  Card buildDocumentCard(BuildContext context, Map<String, dynamic> document) {
    var leadingIconSymbol;
    if (document['statusCodeReason'] != 'OK') {
      leadingIconSymbol = Icons.cancel;
    } else if (document['pinned'] != 0) {
      leadingIconSymbol = Icons.star;
    } else if (document['points'] != null) {
      leadingIconSymbol = Icons.assignment_turned_in;
    } else {
      leadingIconSymbol = Icons.assignment;
    }

    String pointsText = document['points'] != null
        ? 'Points: ' +
            pointsToText(document['points']) +
            '/' +
            pointsToText(document['maximumPoints'])
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
                print('Opened info for document ' +
                    document['title'] +
                    ' with id ' +
                    document['id'].toString());
                Navigator.push(context,
                    MaterialPageRoute<void>(builder: (context) {
                  return DocumentInfoPage(document['id']);
                }));
              },
            ),
            onTap: () {
              print('Document ListTile pressed');
              // TODO: Open the PDF document
            },
          ),
        ],
      ),
    );
  }

  Widget buildContent(BuildContext context, DatabaseState databaseState) {
    List<Map<String, dynamic>> documents =
        databaseState.websiteIdToDocuments(websiteId);
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
            content: Text('A network error occured: \n' + error.toString()),
          ));
        }, test: (error) => error is IOException);
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
      return Scaffold(
        appBar: AppBar(
          title: Text(databaseState.websiteIdToWebsite(websiteId)['name']),
        ),
        body: Builder(
          // This is necessary to use Scaffold.of(innerContext)
          builder: (innerContext) => buildContent(innerContext, databaseState),
        ),
      );
    });
  }
}