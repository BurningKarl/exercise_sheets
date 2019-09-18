import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' as sqflite;


class WebsiteSelectionPageState extends State<WebsiteSelectionPage> {
  sqflite.Database database;

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
    return FutureBuilder(
        future: openDatabase(),
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
                      subtitle: Text('Points: ' + website['maximumPoints'].toString()),
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

  Future openDatabase() {
    return Future(() async {
      database = await sqflite.openDatabase('exercise_sheets.db', version: 1,
          onCreate: (sqflite.Database db, int version) async {
            await db.execute(
                'CREATE TABLE Websites (id INTEGER PRIMARY KEY, name TEXT, url TEXT, maximumPoints INTEGER, username TEXT, password TEXT)');
            await db.insert('Websites', {
              'name': 'GeoTopo',
              'url': 'https://www.math.uni-bonn.de/people/ursula/courses.html',
              'maximumPoints': 50
            });
          });
      return await database.query('Websites');
    });
  }
}

class WebsiteSelectionPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => WebsiteSelectionPageState();
}
