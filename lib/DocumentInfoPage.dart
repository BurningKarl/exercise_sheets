import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'DatabaseState.dart';

class DocumentInfoPage extends StatelessWidget {
  final int documentId;
  final _formKey = GlobalKey<FormState>();

  DocumentInfoPage(this.documentId);

  Widget buildContent() {
    return Consumer<DatabaseState> (
      builder: (context, database, _) {
        return Form(
          key: _formKey,
          child: Scrollbar(
            child: ListView(
              children: <Widget>[
                TextFormField()
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Provider.of<DatabaseState>(context)
            .documentIdToDocument(documentId)['title']),
      ),
      body: buildContent(),
    );
  }
}