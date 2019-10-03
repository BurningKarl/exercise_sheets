import 'package:exercise_sheets/DatabaseState.dart';
import 'package:exercise_sheets/DocumentSelectionPage.dart';
import 'package:exercise_sheets/WebsiteInfoPage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'DatabaseState.dart';

class WebsiteSelectionPage extends StatelessWidget {
  final NumberFormat pointsFormat = NumberFormat.decimalPattern();
  final NumberFormat averageFormat = NumberFormat.percentPattern();

  Widget buildWebsiteItem(BuildContext context, Map<String, dynamic> website,
      DatabaseState databaseState) {
    Map<String, double> stats =
        databaseState.websiteIdToStatistics(website['id']);

    String statsText;
    if (stats['maximum'] != 0) {
      statsText = 'Points: '
          '${pointsFormat.format(stats['achieved'])}'
          '/${pointsFormat.format(stats['maximum'])} '
          ' ~ ${averageFormat.format(stats['achieved'] / stats['maximum'])}';
    }

    // TODO: Consider adding the ability to select websites
    // After one or more websites are selected, a delete button can
    // be shown

    return Dismissible(
      key: Key(website['id'].toString()),
      direction: DismissDirection.horizontal,
      confirmDismiss: (DismissDirection direction) {
        return showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Delete "${website['title']}"?'),
                content:
                    Text('This will delete the website and all corresponding '
                        'documents. It cannot be undone!'),
                actions: <Widget>[
                  FlatButton(
                    child: Text('CANCEL'),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                  ),
                  FlatButton(
                    child: Text('YES'),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                  ),
                ],
              );
            });
      },
      onDismissed: (DismissDirection direction) async {
        // Delete this website
        await databaseState.deleteWebsite(website['id']);
        print('Deleted website ${website['title']} '
            'with id ${website['id']}');
      },
      background: Container(
        color: Colors.red,
        child: Icon(Icons.delete),
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        child: Icon(Icons.delete),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
      ),
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.view_list),
              title: Text(website['title']),
              subtitle: statsText != null ? Text(statsText) : null,
              onTap: () {
                print('Opened selection for website ${website['title']} '
                    'with id ${website['id']}');

                Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) =>
                          DocumentSelectionPage(website['id']),
                    ));
              },
            ),
          ],
        ),
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
