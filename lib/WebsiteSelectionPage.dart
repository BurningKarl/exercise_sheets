import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

class WebsiteSelectionPageState extends State<WebsiteSelectionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exercise Sheets'),
      ),
      body: buildContent(),
    );
  }

  Widget buildContent() {
    Future<sqflite.Database> databaseFuture =
        Provider.of<Future<sqflite.Database>>(context);
    return FutureBuilder(
        future: readDatabase(databaseFuture),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text('Error when opening the database:/n' +
                    snapshot.error.toString()));
          } else if (snapshot.hasData) {
            final List<Map<String, dynamic>> websites = snapshot.data;
            final List<Card> cards =
                websites.map((Map<String, dynamic> website) {
              return Card(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      leading: Icon(Icons.view_list),
                      title: Text(website['name']),
                      subtitle: Text(
                          'Points: ' + website['maximumPoints'].toString()),
                      onTap: () {},
                    ),
                  ],
                ),
              );
            }).toList();
            return ListView(children: cards);
          } else {
            return Center(child: Text('Database was not opened yet'));
          }
        });
  }

  Future readDatabase(Future<sqflite.Database> databaseFuture) {
    return Future(() async {
      return await (await databaseFuture).query('Websites');
    });
  }
}

class WebsiteSelectionPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => WebsiteSelectionPageState();
}
