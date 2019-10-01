import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'DatabaseState.dart';

class DocumentInfoPage extends StatefulWidget {
  final int documentId;

  DocumentInfoPage(this.documentId);

  @override
  DocumentInfoPageState createState() => DocumentInfoPageState(documentId);
}

class DocumentInfoPageState extends State<DocumentInfoPage> {
  final int documentId;
  final _formKey = GlobalKey<FormState>();
  String titleInput;
  String pointsInput;
  String maximumPointsInput;

  DocumentInfoPageState(this.documentId);

  String doubleToString(double value) {
    return value != null ? value.toString() : "";
  }

  int negate(int value) {
    if (value == 0) {
      return 1;
    } else {
      return 0;
    }
  }

  Widget buildContent(BuildContext context, DatabaseState database) {
    Map<String, dynamic> document = database.documentIdToDocument(documentId);
    String lastModified = document['lastModified'] != null
        ? DateTime.parse(document['lastModified']).toLocal().toString()
        : '';

    return Form(
      key: _formKey,
      onWillPop: () async {
        // TODO: Add a warning, if changes were made
        return true;
      },
      child: Scrollbar(
        child: ListView(
          padding: EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              initialValue: document['title'],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Title',
                icon: Icon(Icons.description),
              ),
              minLines: 1,
              maxLines: 2,
              validator: (String value) {
                if (value.trim().isEmpty) {
                  return 'Please enter a name';
                } else {
                  return null;
                }
              },
              onSaved: (String value) {
                titleInput = value;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Title on the website',
                icon: Icon(Icons.description),
              ),
              initialValue: document['titleOnWebsite'],
              enabled: false,
              minLines: 1,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Last modified on the website',
                icon: Icon(Icons.event),
              ),
              initialValue: lastModified,
              enabled: false,
            ),
            const SizedBox(
              height: 16,
            ),
            Row(
              children: <Widget>[
                Expanded(
                  flex: 10,
                  child: TextFormField(
                    initialValue: doubleToString(document['points']),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      icon: Icon(Icons.assignment_turned_in),
                      labelText: 'Achieved points',
                    ),
                    keyboardType: TextInputType.numberWithOptions(
                      signed: false,
                      decimal: true,
                    ),
                    validator: (String value) {
                      if (value.trim().isNotEmpty &&
                          double.tryParse(value) == null) {
                        return 'Enter a number or leave blank';
                      } else {
                        return null;
                      }
                    },
                    onSaved: (String value) {
                      pointsInput = value;
                    },
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '/',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 160,
                  child: TextFormField(
                    initialValue: doubleToString(document['maximumPoints']),
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Maximum points'),
                    keyboardType: TextInputType.numberWithOptions(
                      signed: false,
                      decimal: true,
                    ),
                    validator: (String value) {
                      if (double.tryParse(value) == null) {
                        return 'Enter a number';
                      } else {
                        return null;
                      }
                    },
                    onSaved: (String value) {
                      maximumPointsInput = value;
                    },
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseState>(builder: (context, databaseState, _) {
      Map<String, dynamic> document =
          databaseState.documentIdToDocument(documentId);
      return Scaffold(
        appBar: AppBar(
          title: Text(document['title']),
          actions: <Widget>[
            IconButton(
              icon: Icon(
                  document['archived'] == 0 ? Icons.archive : Icons.unarchive),
              tooltip: document['archived'] == 0 ? 'Archive' : 'Unarchive',
              onPressed: () {
                Map<String, dynamic> alteredDocument = Map.from(document);
                alteredDocument['archived'] = negate(document['archived']);
                databaseState.setDocument(alteredDocument);
              },
            ),
            IconButton(
              icon: Icon(
                  document['pinned'] == 0 ? Icons.star_border : Icons.star),
              tooltip: document['pinned'] == 0 ? 'Pin' : 'Unpin',
              onPressed: () {
                Map<String, dynamic> alteredDocument = Map.from(document);
                alteredDocument['pinned'] = negate(document['pinned']);
                databaseState.setDocument(alteredDocument);
              },
            ),
          ],
        ),
        body: buildContent(context, databaseState),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.check),
          tooltip: 'Submit',
          onPressed: () {
            if (_formKey.currentState.validate()) {
              _formKey.currentState.save();
              Map<String, dynamic> alteredDocument = Map.from(document);
              alteredDocument.addAll({
                'title': titleInput,
                'points': double.tryParse(pointsInput),
                'maximumPoints': double.tryParse(maximumPointsInput),
              });
              databaseState.setDocument(alteredDocument);
              Navigator.pop(context);
            }
          },
        ),
      );
    });
  }
}
