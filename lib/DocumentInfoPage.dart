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

  // TODO: Add submit option to the form
  Widget buildContent(BuildContext context, DatabaseState database) {
    Map<String, dynamic> document = database.documentIdToDocument(documentId);
    String lastModified = document['lastModified'] != null
        ? DateTime.parse(document['lastModified']).toLocal().toString()
        : '';
    return Form(
      key: _formKey,
      onWillPop: () async {
        return true;
      },
      child: Scrollbar(
        child: ListView(
          padding: EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              initialValue: document['title'],
              minLines: 1,
              maxLines: 2,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Title',
                icon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: document['titleOnWebsite'],
              enabled: false,
              minLines: 1,
              maxLines: 2,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Title on the website',
                icon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: lastModified,
              enabled: false,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Last modified on the website',
                icon: Icon(Icons.event),
              ),
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
                    keyboardType: TextInputType.numberWithOptions(
                      signed: false,
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      icon: Icon(Icons.assignment_turned_in),
                      labelText: 'Achieved points',
                    ),
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
                  width: 150,
                  child: TextFormField(
                    initialValue: doubleToString(document['maximumPoints']),
                    keyboardType: TextInputType.numberWithOptions(
                      signed: false,
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Maximum points'),
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
              onPressed: () {
                Map<String, dynamic> alteredDocument = Map.from(document);
                alteredDocument['archived'] = negate(document['archived']);
                databaseState.setDocument(alteredDocument);
              },
            ),
            IconButton(
              icon: Icon(
                  document['pinned'] == 0 ? Icons.star_border : Icons.star),
              onPressed: () {
                Map<String, dynamic> alteredDocument = Map.from(document);
                alteredDocument['pinned'] = negate(document['pinned']);
                databaseState.setDocument(alteredDocument);
              },
            )
          ],
        ),
        body: buildContent(context, databaseState),
      );
    });
  }
}