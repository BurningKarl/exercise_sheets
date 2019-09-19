import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

class NetworkOperations {
  static Future<List<Map<String, dynamic>>> retrieveDocumentMetadata(
      String url, String username, String password) async {
    // TODO: Support basic authentication
    var response = await http.get(url);
    if (response.statusCode != 200) {
      throw http.ClientException('Unexpected response code ' +
          response.statusCode.toString() +
          ' when connecting to ' +
          url);
    } else {
      print(response.body);
      Document htmlDocument = parse(response.body);
      for (Element element in htmlDocument.getElementsByTagName('a')) {
        if (element.attributes.containsKey('href') &&
            element.attributes['href'].endsWith('.pdf')) {
          print(element.attributes['href']);
        }
      }
    }

    // TODO: Receive the document metadata by HEAD requests
    // TODO: Translate the data into a usable format

    return List();
  }
}
