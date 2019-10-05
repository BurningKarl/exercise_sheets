import 'dart:io';

import 'package:path_provider/path_provider.dart';

class StorageOperations {
  static Future<Directory> websiteIdToPdfDirectory(int websiteId) async {
    Directory baseDirectory = await getExternalStorageDirectory();
    return Directory(baseDirectory.path + '/$websiteId');
  }

  static Future<File> documentToPdfFile(
      Map<String, dynamic> document, String fileName,
      {bool create = false}) async {
    Directory baseDirectory =
        await websiteIdToPdfDirectory(document['websiteId']);
    return File(baseDirectory.path + '/$fileName');
  }

  static Future<File> exportFile() async {
    Directory baseDirectory = await getExternalStorageDirectory();
    return File(baseDirectory.path + '/exercise_sheets.json');
  }
}
