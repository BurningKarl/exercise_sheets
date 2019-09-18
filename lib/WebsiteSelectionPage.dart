import 'package:exercise_sheets/DatabaseState.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'DatabaseState.dart';

class WebsiteSelectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exercise Sheets'),
      ),
      body: buildContent(),
    );
  }

  Card buildWebsiteCard(Map<String, dynamic> website) {
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.view_list),
            title: Text(website['name']),
            subtitle: Text('Points: ' + website['maximumPoints'].toString()),
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
            children: databaseState.websites.map(buildWebsiteCard).toList());
      },
    );
  }
}