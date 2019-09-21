import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'DatabaseState.dart';

class DocumentSelectionPage extends StatelessWidget {
  final int websiteId;

  const DocumentSelectionPage(this.websiteId);

  Card buildDocumentCard(BuildContext context, Map<String, dynamic> document) {
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.assignment),
            title: Text(document['name']),
            subtitle: Text('Points: ' +
                document['points'].toString() +
                '/' +
                document['maximumPoints'].toString()),
            trailing: IconButton(
              icon: Icon(Icons.info),
              onPressed: () {
                print('Info button pressed');
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
