import 'dart:io';

import 'package:exercise_sheets/DatabaseState.dart';
import 'package:exercise_sheets/StorageOperations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum ExportOption { EXPORT, IMPORT, CANCEL }

class ImportExportDialogs {
  static Future<void> handleExport(
      BuildContext context, DatabaseState databaseState) async {
    File file = await StorageOperations.exportFile();
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
                TextButton(
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
                TextButton(
                  child: Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          });
    });
  }

  static Future<void> handleImport(
      BuildContext context, DatabaseState databaseState) async {
    FilePickerResult result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (result == null) return;
    File file = File(result.files.single.path);

    databaseState.importFromFile(file).then((_) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Import successful'),
              content: Text('Your exercise sheets were successfully imported '
                  'from "${file.path}".'),
              actions: <Widget>[
                TextButton(
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
                TextButton(
                  child: Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          });
    });
  }

  static Future<void> handleImportExport(
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
              TextButton(
                child: Text('CANCEL'),
                onPressed: () {
                  Navigator.of(context).pop(ExportOption.CANCEL);
                },
              ),
              TextButton(
                child: Text('IMPORT'),
                onPressed: () {
                  Navigator.of(context).pop(ExportOption.IMPORT);
                },
              ),
              TextButton(
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
}
