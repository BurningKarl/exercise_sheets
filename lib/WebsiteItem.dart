import 'package:exercise_sheets/DocumentSelectionPage.dart';
import 'package:exercise_sheets/WebsiteSelectionPage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

typedef ToggleSelectionCallback = void Function();

class WebsiteItem extends StatelessWidget {
  final NumberFormat pointsFormat = NumberFormat.decimalPattern();
  final NumberFormat averageFormat = NumberFormat.percentPattern();

  final Map<String, dynamic> website;
  final Map<String, double> stats;
  final ConfirmDismissCallback confirmDelete;
  final DismissDirectionCallback onDelete;
  final ToggleSelectionCallback onToggleSelection;

  WebsiteItem({
    @required this.website,
    @required this.stats,
    @required this.onToggleSelection,
    this.confirmDelete,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    String statsText;
    if (stats['maximum'] != 0) {
      statsText = 'Points: '
          '${pointsFormat.format(stats['achieved'])}'
          '/${pointsFormat.format(stats['maximum'])} '
          ' ~ ${averageFormat.format(stats['achieved'] / stats['maximum'])}';
    }

    return Consumer<SelectedWebsites>(
      builder: (context, selectedWebsites, _) {
        Widget tile = Card(
          color: selectedWebsites.isSelected(website['id'])
              ? Colors.grey[400]
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.view_list),
                title: Text(website['title']),
                subtitle: statsText != null ? Text(statsText) : null,
                onTap: () {
                  if (selectedWebsites.inSelectionMode()) {
                    onToggleSelection();
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
                  onToggleSelection();
                },
              ),
            ],
          ),
        );

        if (!selectedWebsites.inSelectionMode()) {
          return Dismissible(
            key: Key(website['id'].toString()),
            direction: DismissDirection.horizontal,
            confirmDismiss: confirmDelete,
            onDismissed: onDelete,
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
            child: tile,
          );
        } else {
          return tile;
        }
      },
    );
  }
}
