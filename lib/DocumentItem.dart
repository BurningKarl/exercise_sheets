import 'package:exercise_sheets/DocumentInfoPage.dart';
import 'package:exercise_sheets/DocumentSelectionPage.dart';
import 'package:exercise_sheets/NetworkOperations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';

typedef ToggleSelectionCallback = void Function();

class DocumentItem extends StatelessWidget {
  final NumberFormat pointsFormat = NumberFormat.decimalPattern();

  final Map<String, dynamic> document;
  final bool enableDismiss;
  final ConfirmDismissCallback confirmArchive;
  final DismissDirectionCallback onArchived;
  final ToggleSelectionCallback onToggleSelection;

  DocumentItem({
    @required this.document,
    @required this.enableDismiss,
    @required this.onToggleSelection,
    this.confirmArchive,
    this.onArchived,
  });

  String pointsToString(double value) {
    return value != null ? pointsFormat.format(value) : null;
  }

  Text pointsText() {
    return document['points'] != null
        ? Text('Points: ${pointsToString(document['points'])}'
            '/${pointsToString(document['maximumPoints'])}')
        : null;
  }

  IconData leadingIconSymbol() {
    if (document['statusMessage'] != 'OK') {
      return Icons.cancel;
    } else if (document['archived'] != 0) {
      return Icons.archive;
    } else if (document['pinned'] != 0) {
      return Icons.star;
    } else if (document['points'] != null) {
      return Icons.assignment_turned_in;
    } else {
      return Icons.assignment;
    }
  }

  void showSnackBar(BuildContext context, String content) {
    Scaffold.of(context).showSnackBar(SnackBar(
      content: Text(content),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SelectedDocuments>(
      builder: (context, selectedDocuments, _) {
        Widget tile = Card(
          color: selectedDocuments.isSelected(document['id'])
              ? Colors.grey[400]
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(
                  leadingIconSymbol(),
                  color: document['file'] != null ? Colors.green : null,
                ),
                title: Text(document['title']),
                subtitle: pointsText(),
                trailing: IconButton(
                  icon: Icon(Icons.info),
                  onPressed: () {
                    print('Opened info for document ${document['title']} '
                        'with id ${document['id']}');
                    Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) =>
                              DocumentInfoPage(document['id']),
                        ));
                  },
                ),
                onTap: () async {
                  if (selectedDocuments.inSelectionMode()) {
                    onToggleSelection();
                    return;
                  }

                  print('Tried to open document ${document['title']} '
                      'with id ${document['id']}');
                  if (document['file'] != null) {
                    print('Opened locally');
                    await OpenFile.open(document['file']);
                  } else if (document['statusMessage'] == 'OK') {
                    print('Opened by url');
                    NetworkOperations.launchUrl(document['url']);
                  } else {
                    print('Not opened: ${document['statusMessage']}');
                    showSnackBar(
                        context,
                        'This document is unreachable: ' +
                            document['statusMessage']);
                  }
                },
                onLongPress: () {
                  onToggleSelection();
                },
              ),
            ],
          ),
        );

        if (enableDismiss && !selectedDocuments.inSelectionMode()) {
          return Dismissible(
            key: Key(document['id'].toString()),
            direction: DismissDirection.horizontal,
            confirmDismiss: confirmArchive,
            onDismissed: onArchived,
            background: Container(
              color: Colors.blue,
              child: Icon(Icons.archive),
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
            secondaryBackground: Container(
              color: Colors.blue,
              child: Icon(Icons.archive),
              alignment: Alignment.centerRight,
              padding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
            child: tile,
          );
        } else {
          return tile;
        }
      },
    );
  }
}
