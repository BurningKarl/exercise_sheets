import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'DatabaseState.dart';

class DocumentInfoPage extends StatelessWidget {
  final int documentId;
  final _formKey = GlobalKey<FormState>();

  DocumentInfoPage(this.documentId);

  Widget buildContent(BuildContext context, DatabaseState database) {
    return Form(
      key: _formKey,
      child: Scrollbar(
        child: ListView(
          children: <Widget>[TextFormField()],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseState>(builder: (context, databaseState, _) {
      return Scaffold(
        appBar: AppBar(
          title: Text(databaseState.documentIdToDocument(documentId)['title']),
        ),
        body: buildContent(context, databaseState),
      );
    });
  }
}