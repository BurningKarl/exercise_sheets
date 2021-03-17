import 'package:exercise_sheets/DatabaseState.dart';
import 'package:exercise_sheets/ImportExportDialogs.dart';
import 'package:exercise_sheets/WebsiteInfoPage.dart';
import 'package:exercise_sheets/WebsiteItem.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

import 'DatabaseState.dart';

class SelectedWebsites extends DelegatingList<int> with ChangeNotifier {
  SelectedWebsites(List<int> base) : super(base);

  void clear() {
    super.clear();
    notifyListeners();
  }

  bool isSelected(int websiteId) {
    return contains(websiteId);
  }

  bool inSelectionMode() {
    return isNotEmpty;
  }

  void toggleSelection(int websiteId) {
    if (contains(websiteId)) {
      remove(websiteId);
    } else {
      add(websiteId);
    }
    notifyListeners();
  }
}

class WebsiteSelectionPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => WebsiteSelectionPageState();
}

class WebsiteSelectionPageState extends State<WebsiteSelectionPage> {
  final NumberFormat pointsFormat = NumberFormat.decimalPattern();
  final NumberFormat averageFormat = NumberFormat.percentPattern();

  final SelectedWebsites selectedWebsites = SelectedWebsites([]);

  Future<bool> confirmDeletion(
      List<int> toBeDeleted, DatabaseState databaseState) {
    String title, content;
    if (toBeDeleted.length == 1) {
      var website = databaseState.websiteIdToWebsite(toBeDeleted.single);
      title = 'Delete "${website['title']}"?';
      content = 'This will delete the website and all corresponding documents. '
          'It cannot be undone!';
    } else {
      var escapedWebsiteTitles = toBeDeleted
          .map((websiteId) =>
              databaseState.websiteIdToWebsite(websiteId)['title'])
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
              TextButton(
                child: Text('CANCEL'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: Text('YES'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        });
  }

  Future<void> deleteWebsites(
      List<int> toBeDeleted, DatabaseState databaseState) async {
    var websites = toBeDeleted
        .map((websiteId) => databaseState.websiteIdToWebsite(websiteId))
        .toList(); // toList is necessary to avoid lazy evaluation
    var websiteIds = websites.map((website) => website['id'] as int);
    await databaseState.deleteWebsites(websiteIds);

    for (var website in websites) {
      print('Deleted website ${website['title']} '
          'with id ${website['id']}');
    }
  }

  Widget buildContent(BuildContext context, DatabaseState databaseState) {
    if (databaseState.databaseError) {
      return Center(
        child: Text('The database could not be opened'),
      );
    } else {
      return Scrollbar(
        child: ChangeNotifierProvider<SelectedWebsites>.value(
          value: selectedWebsites,
          child: ListView.builder(
            itemCount: databaseState.websites.length,
            itemBuilder: (BuildContext context, int index) {
              Map<String, dynamic> website = databaseState.websites[index];

              return WebsiteItem(
                website: website,
                stats: databaseState.websiteIdToStatistics(website['id']),
                onToggleSelection: () {
                  setState(() {
                    selectedWebsites.toggleSelection(website['id']);
                  });
                },
                confirmDelete: (_) =>
                    confirmDeletion([website['id']], databaseState),
                onDelete: (_) => deleteWebsites([website['id']], databaseState),
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseState>(
      builder: (context, databaseState, _) {
        AppBar appBar;
        if (selectedWebsites.inSelectionMode()) {
          appBar = AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  selectedWebsites.clear();
                });
              },
            ),
            title: Text(selectedWebsites.length.toString()),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () async {
                  if (await confirmDeletion(selectedWebsites, databaseState)) {
                    await deleteWebsites(selectedWebsites, databaseState);
                    setState(() {
                      selectedWebsites.clear();
                    });
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
