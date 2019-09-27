import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'DatabaseState.dart';

class WebsiteInfoPage extends StatefulWidget {
  final int websiteId;

  WebsiteInfoPage(this.websiteId);

  @override
  WebsiteInfoPageState createState() => WebsiteInfoPageState(websiteId);
}

class WebsiteInfoPageState extends State<WebsiteInfoPage> {
  final int websiteId;
  final _formKey = GlobalKey<FormState>();
  String titleInput;
  String urlInput;
  String usernameInput;
  String passwordInput;
  String maximumPointsInput;

  WebsiteInfoPageState(this.websiteId);

  String doubleToString(double value) {
    return value != null ? value.toString() : "";
  }

  Widget buildContent(BuildContext context, DatabaseState database) {
    Map<String, dynamic> website = database.websiteIdToWebsite(websiteId);

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
              initialValue: website['title'],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Title',
                icon: Icon(Icons.description),
              ),
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
              initialValue: website['url'],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'URL',
                icon: Icon(Icons.web),
              ),
              keyboardType: TextInputType.url,
              validator: (String value) {
                // TODO: Validate the url with the package validators
                return null;
              },
              onSaved: (String value) {
                urlInput = value;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: doubleToString(website['maximumPoints']),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Maximum points',
                icon: Icon(Icons.assignment_turned_in),
              ),
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
            const SizedBox(height: 16),
            TextFormField(
              initialValue: website['username'],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Username',
                icon: Icon(Icons.account_circle),
              ),
              onSaved: (String value) {
                usernameInput = value;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: website['password'],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Password',
                icon: Icon(Icons.vpn_key),
              ),
              onSaved: (String value) {
                passwordInput = value;
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseState>(builder: (context, databaseState, _) {
      Map<String, dynamic> website =
          databaseState.websiteIdToWebsite(websiteId);
      return Scaffold(
        appBar: AppBar(
          title: Text(website['title']),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.check),
              tooltip: 'Submit',
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  _formKey.currentState.save();
                  Map<String, dynamic> alteredWebsite = Map.from(website);
                  alteredWebsite.addAll({
                    'title': titleInput,
                    'url': urlInput,
                    'username': usernameInput,
                    'password': passwordInput,
                    'maximumPoints': maximumPointsInput,
                  });
                  databaseState.setWebsite(alteredWebsite);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        body: buildContent(context, databaseState),
      );
    });
  }
}
