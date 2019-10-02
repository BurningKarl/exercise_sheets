import 'package:exercise_sheets/DatabaseState.dart';
import 'package:exercise_sheets/DocumentSelectionPage.dart';
import 'package:exercise_sheets/WebsiteInfoPage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'DatabaseState.dart';

class WebsiteSelectionPage extends StatelessWidget {
  NumberFormat pointsFormat = NumberFormat.decimalPattern();
  NumberFormat averageFormat = NumberFormat.percentPattern();

  Widget buildWebsiteItem(BuildContext context, Map<String, dynamic> website,
      DatabaseState databaseState) {
    Map<String, double> stats =
        databaseState.websiteIdToStatistics(website['id']);

    String statsText;
    if (stats['maximum'] != 0) {
      statsText = 'Points: '
          '${pointsFormat.format(stats['achieved'])}'
          '/${pointsFormat.format(stats['maximum'])} '
          ' ~ ${averageFormat.format(stats['achieved']/stats['maximum'])}';
    }

    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.view_list),
            title: Text(website['title']),
            subtitle: statsText != null ? Text(statsText) : null,
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                // TODO: Consider adding the ability to select websites
                // After one or more websites are selected, a delete button can
                // be shown
                // TODO: Consider a swipe gesture to delete a website
                print('Deleted website ${website['title']} '
                    'with id ${website['id']}');
                databaseState.deleteWebsite(website['id']);
              },
            ),
            onTap: () {
              print('Opened selection for website ${website['title']} '
                  'with id ${website['id']}');

              Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => DocumentSelectionPage(website['id']),
                  ));
            },
          ),
        ],
      ),
    );
  }

  Widget buildContent(BuildContext context, DatabaseState databaseState) {
    if (databaseState.databaseError) {
      return Center(
        child: Text('The database could not be opened'),
      );
    } else {
      return Scrollbar(
        child: ListView.builder(
            itemCount: databaseState.websites.length,
            itemBuilder: (context, int index) {
              return buildWebsiteItem(
                  context, databaseState.websites[index], databaseState);
            }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseState>(
      builder: (context, databaseState, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Exercise sheets'),
          ),
          body: buildContent(context, databaseState),
          floatingActionButton: FloatingActionButton(
            child: Icon(Icons.add),
            onPressed: () {
              print('Opened WebsiteInfoPage for a new website');

              Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => WebsiteInfoPage(null),
                  ));
            },
          ),
        );
      },
    );
  }
}
