import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'DatabaseState.dart';

class DocumentSelectionPage extends StatelessWidget {
  final int websiteId;

  const DocumentSelectionPage(this.websiteId);

  Card buildDocumentCard(Map<String, dynamic> document) {
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.view_list),
            title: Text(document['name']),
            subtitle: Text('Points: ' + document['maximumPoints'].toString()),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget buildContent() {
    return Consumer<DatabaseState>(
      builder: (context, databaseState, _) {
        if (databaseState.databaseError) {
          return Center(
            child: Text('The database could not be opened'),
          );
        }
        return ListView(
          children: databaseState.documents
              .where((document) => document['website_id'] == websiteId)
              .map(buildDocumentCard)
              .toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exercise Sheets'),
      ),
      body: buildContent(),
    );
  }
}
