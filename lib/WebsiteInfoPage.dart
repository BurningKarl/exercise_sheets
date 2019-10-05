import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:validators/validators.dart';

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
  final NumberFormat pointsFormat = NumberFormat.decimalPattern();
  String titleInput;
  String urlInput;
  String usernameInput;
  String passwordInput;
  String maximumPointsInput;

  WebsiteInfoPageState(this.websiteId);

  String pointsToString(double value) {
    return value != null ? pointsFormat.format(value) : null;
  }

  Widget buildContent(BuildContext context, DatabaseState database) {
    Map<String, dynamic> website = database.websiteIdToWebsite(websiteId);

    return Form(
      key: _formKey,
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
                if (!isURL(value, requireTld: true, requireProtocol: true)) {
                  return 'Please enter a valid URL';
                } else {
                  return null;
                }
              },
              onSaved: (String value) {
                urlInput = value;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: pointsToString(website['maximumPoints']),
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
        ),
        body: buildContent(context, databaseState),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.check),
          tooltip: 'Submit',
          onPressed: () {
            if (_formKey.currentState.validate()) {
              _formKey.currentState.save();
              databaseState.updateWebsite(website['id'], {
                'title': titleInput,
                'url': urlInput,
                'username': usernameInput,
                'password': passwordInput,
                'maximumPoints': maximumPointsInput,
              });
              Navigator.pop(context);
            }
          },
        ),
      );
    });
  }
}
