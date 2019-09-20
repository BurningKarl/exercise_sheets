import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

class NetworkOperations {
  static Future<List<Map<String, dynamic>>> retrieveDocumentMetadata(
      String url, String username, String password) async {
    // TODO: Support basic authentication
    Document htmlDocument = parse(await http.read(url));

    List<Element> documentElements =
        htmlDocument.getElementsByTagName('a').where((Element element) {
      return element.attributes.containsKey('href') &&
          element.attributes['href'].endsWith('.pdf');
    }).toList();

    List<Map<String, dynamic>> documents = List();

    for (Element documentElement in documentElements) {
      http.Response response =
          await http.head(documentElement.attributes['href']);

      if (response.reasonPhrase == 'OK') {
        print('OK');
        assert(response.headers['content-type'] == 'application/pdf');
        assert(response.headers.containsKey('last-modified'));
      }

      documents.add({
        'name': documentElement.innerHtml,
        'url': documentElement.attributes['href'],
        'lastModified': response.headers['last-modified'],
        'statusCodeReason': response.reasonPhrase,
      });
    }

    return documents;
  }
}
