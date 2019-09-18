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
            leading: Icon(Icons.assignment),
            title: Text(document['name']),
            subtitle: Text('Points: ' + document['points'].toString() + '/' + document['maximumPoints'].toString()),
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
      // TODO: Find the website with the correct websiteId
      appBar: AppBar(
        title: Text(Provider.of<DatabaseState>(context).websites.first['name']),
      ),
      body: buildContent(),
    );
  }
}
