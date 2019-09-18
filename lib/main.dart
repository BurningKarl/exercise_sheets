import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exercise Sheets',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        cardTheme: CardTheme(
          margin: EdgeInsets.all(7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(7)),
          )
        )
      ),
      home: WebsiteSelectionPage(),
    );
  }
}

class WebsiteSelectionPageState extends State<WebsiteSelectionPage> {
  sqflite.Database database;

//  List<Map<String, dynamic>> websites;

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
