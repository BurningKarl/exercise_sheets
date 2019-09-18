import 'package:sqflite/sqflite.dart' as sqflite;

class DatabaseBuilder {

  static Future<sqflite.Database> openDatabase(context) {
    return Future(() async {
      return await sqflite.openDatabase('exercise_sheets.db', version: 1,
          onCreate: (sqflite.Database db, int version) async {
        await db.execute(
            'CREATE TABLE Websites (id INTEGER PRIMARY KEY, name TEXT, url TEXT, maximumPoints INTEGER, username TEXT, password TEXT)');
        await db.insert('Websites', {
          'name': 'GeoTopo',
          'url': 'https://www.math.uni-bonn.de/people/ursula/courses.html',
          'maximumPoints': 50
        });
      });
    });
  }
}
