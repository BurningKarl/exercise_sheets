import 'package:exercise_sheets/DatabaseState.dart';
import 'package:exercise_sheets/DocumentSelectionPage.dart';
import 'package:exercise_sheets/ImportExportDialogs.dart';
import 'package:exercise_sheets/WebsiteInfoPage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'DatabaseState.dart';

class WebsiteSelectionPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => WebsiteSelectionPageState();
}

class WebsiteSelectionPageState extends State<WebsiteSelectionPage> {
  final NumberFormat pointsFormat = NumberFormat.decimalPattern();
  final NumberFormat averageFormat = NumberFormat.percentPattern();

  final List<int> selectedItems = List();
  DatabaseState databaseState;

  bool isSelected(int index) => selectedItems.contains(index);

  bool isInSelectionMode() {
    return selectedItems.isNotEmpty;
  }

  void toggleSelection(int index) {
    setState(() {
      if (selectedItems.contains(index)) {
        selectedItems.remove(index);
      } else {
        selectedItems.add(index);
      }
    });
  }

  Future<bool> confirmDeletion(List<int> toBeDeleted) {
    String title, content;
    if (toBeDeleted.length == 1) {
      var website = databaseState.websites[toBeDeleted.single];
      title = 'Delete "${website['title']}"?';
      content = 'This will delete the website and all corresponding documents. '
          'It cannot be undone!';
    } else {
      var escapedWebsiteTitles = toBeDeleted
          .map((index) => databaseState.websites[index]['title'])
          .map((title) => '"$title"');
      var websitesString = escapedWebsiteTitles.join(', ');
      title = 'Delete ${toBeDeleted.length} websites?';
      content = 'This will delete the websites $websitesString and all their '
          'documents. It cannot be undone!';
    }
    return showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(content),
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
  }

  Future<void> deleteWebsites(List<int> toBeDeleted) async {
    var websites = toBeDeleted
        .map((index) => Map.from(databaseState.websites[index]))
        .toList();
    var websiteIds = websites.map((website) => website['id'] as int);
    await databaseState.deleteWebsites(websiteIds);

    for (var website in websites) {
      print('Deleted website ${website['title']} '
          'with id ${website['id']}');
    }
  }

  Widget buildWebsiteItem(BuildContext context, int index) {
    Map<String, dynamic> website = databaseState.websites[index];
    Map<String, double> stats =
        databaseState.websiteIdToStatistics(website['id']);

    String statsText;
    if (stats['maximum'] != 0) {
      statsText = 'Points: '
          '${pointsFormat.format(stats['achieved'])}'
          '/${pointsFormat.format(stats['maximum'])} '
          ' ~ ${averageFormat.format(stats['achieved'] / stats['maximum'])}';
    }

    return Dismissible(
      key: Key(website['id'].toString()),
      direction: DismissDirection.horizontal,
      confirmDismiss: (DismissDirection direction) => confirmDeletion([index]),
      onDismissed: (DismissDirection direction) => deleteWebsites([index]),
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
        color: isSelected(index) ? Colors.grey[400] : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.view_list),
              title: Text(website['title']),
              subtitle: statsText != null ? Text(statsText) : null,
              onTap: () {
                if (isInSelectionMode()) {
                  toggleSelection(index);
                  return;
                }

                print('Opened selection for website ${website['title']} '
                    'with id ${website['id']}');

                Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) =>
                          DocumentSelectionPage(website['id']),
                    ));
              },
              onLongPress: () {
                toggleSelection(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildContent(BuildContext context) {
    if (databaseState.databaseError) {
      return Center(
        child: Text('The database could not be opened'),
      );
    } else {
      return Scrollbar(
        child: ListView.builder(
          itemCount: databaseState.websites.length,
          itemBuilder: (context, int index) => buildWebsiteItem(context, index),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseState>(
      builder: (context, newDatabaseState, _) {
        databaseState = newDatabaseState;

        AppBar appBar;
        if (isInSelectionMode()) {
          appBar = AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  selectedItems.clear();
                });
              },
            ),
            title: Text(selectedItems.length.toString()),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () async {
                  if (await confirmDeletion(selectedItems)) {
                    var selectedItemsCopy = List<int>.from(selectedItems);
                    selectedItems.clear();
                    await deleteWebsites(selectedItemsCopy);
                  }
                },
              )
            ],
          );
        } else {
          appBar = AppBar(
            title: Text('Exercise sheets'),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.import_export),
                onPressed: () => ImportExportDialogs.handleImportExport(
                    context, databaseState),
              )
            ],
          );
        }

        return Scaffold(
          appBar: appBar,
          body: buildContent(context),
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
