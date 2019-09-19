import 'package:exercise_sheets/DatabaseState.dart';
import 'package:exercise_sheets/DocumentSelectionPage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'DatabaseState.dart';

class WebsiteSelectionPage extends StatelessWidget {
  Card buildWebsiteCard(context, Map<String, dynamic> website) {
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.view_list),
            title: Text(website['name']),
            subtitle: Text('Points: ' + website['maximumPoints'].toString()),
            onTap: () {
              print('Opened selection for website ' +
                  website['name'] +
                  ' with id ' +
                  website['id'].toString());

              Navigator.push(context,
                  MaterialPageRoute<void>(builder: (context) {
                return DocumentSelectionPage(website['id']);
              }));
            },
          ),
        ],
      ),
    );
  }

  Widget buildContent() {
    return Consumer<DatabaseState>(
      builder: (context, databaseState, _) {
        return ListView.builder(
            itemCount: databaseState.websites.length,
            itemBuilder: (context, int index) {
              return buildWebsiteCard(context, databaseState.websites[index]);
            });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exercise sheets'),
      ),
      body: buildContent(),
    );
  }
}
