import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'DatabaseState.dart';

class DocumentSelectionPage extends StatelessWidget {
  final int websiteId;

  const DocumentSelectionPage(this.websiteId);

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

    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: Icon(leadingIconSymbol),
            title: Text(document['title']),
            subtitle: Text('Points: ' +
                document['points'].toString() +
                '/' +
                document['maximumPoints'].toString()),
            trailing: IconButton(
              icon: Icon(Icons.info),
              onPressed: () {
                print('Info button pressed');
                // TODO: Open info screen for this document
                // with the option to pin the document to the top
              },
            ),
            onTap: () {
              print('Document ListTile pressed');
            },
          ),
        ],
      ),
    );
  }

  Widget buildContent() {
    return Consumer<DatabaseState>(
      builder: (context, databaseState, _) {
        List<Map<String, dynamic>> documents =
            databaseState.websiteIdToDocuments(websiteId);
        if (databaseState.databaseError) {
          return Center(
            child: Text('The database could not be opened'),
          );
        }
        return RefreshIndicator(
          onRefresh: () {
            return databaseState.updateDocumentMetadata(websiteId);
          },
          child: Scrollbar(
            child: ListView.builder(
                itemCount: documents.length,
                itemBuilder: (context, int index) {
                  return buildDocumentCard(context, documents[index]);
                }),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Provider.of<DatabaseState>(context)
            .websiteIdToWebsite(websiteId)['name']),
      ),
      body: buildContent(),
    );
  }
}
