import 'dart:io';

import 'package:exercise_sheets/DatabaseState.dart';
import 'package:exercise_sheets/DocumentSelectionPage.dart';
import 'package:exercise_sheets/WebsiteInfoPage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'DatabaseState.dart';

enum ExportOption { EXPORT, IMPORT, CANCEL }

class WebsiteSelectionPage extends StatelessWidget {
  final NumberFormat pointsFormat = NumberFormat.decimalPattern();
  final NumberFormat averageFormat = NumberFormat.percentPattern();

  Future<void> handleExport(
      BuildContext context, DatabaseState databaseState) async {
    Directory baseDirectory = await getExternalStorageDirectory();
    var file = File(baseDirectory.path + '/exercise_sheets.json');
    print(file.path);

    databaseState.exportToFile(file).then((_) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Export successful'),
              content: Text('Your exercise sheets were succesfully exported to '
                  '"${file.path}".'),
              actions: <Widget>[
                FlatButton(
                  child: Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          });
    }).catchError((error) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Export failed'),
              content:
                  Text('Your exercise sheets could not be exported: $error'),
              actions: <Widget>[
                FlatButton(
                  child: Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          });
    });
  }

  Future<void> handleImport(
      BuildContext context, DatabaseState databaseState) async {
    File file = File(await FilePicker.getFilePath(
        type: FileType.ANY, fileExtension: 'json'));

    databaseState.importFromFile(file).then((_) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Import successful'),
              content: Text('Your exercise sheets were succesfully imported '
                  'from "${file.path}".'),
              actions: <Widget>[
                FlatButton(
                  child: Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          });
    }).catchError((error) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Import failed'),
              content:
                  Text('Your exercise sheets could not be imported: $error'),
              actions: <Widget>[
                FlatButton(
                  child: Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          });
    });
  }

  Future<void> handleImportExport(
      BuildContext context, DatabaseState databaseState) async {
    var option = await showDialog<ExportOption>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Import or export'),
            content: Text(
                'You can import and export your websites and corresponding '
                'exercise sheets inluding their points, but without the actual '
                'PDF files.'),
            actions: <Widget>[
              FlatButton(
                child: Text('CANCEL'),
                onPressed: () {
                  Navigator.of(context).pop(ExportOption.CANCEL);
                },
              ),
              FlatButton(
                child: Text('IMPORT'),
                onPressed: () {
                  Navigator.of(context).pop(ExportOption.IMPORT);
                },
              ),
              FlatButton(
                child: Text('EXPORT'),
                onPressed: () {
                  Navigator.of(context).pop(ExportOption.EXPORT);
                },
              ),
            ],
          );
        });

    switch (option) {
      case ExportOption.EXPORT:
        await handleExport(context, databaseState);
        break;
      case ExportOption.IMPORT:
        await handleImport(context, databaseState);
        break;
      case ExportOption.CANCEL:
        break;
    }
  }

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
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.import_export),
                onPressed: () => handleImportExport(context, databaseState),
              )
            ],
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
