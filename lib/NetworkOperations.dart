import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

class NetworkOperations {
  static Future<List<Map<String, dynamic>>> retrieveDocumentMetadata(
      String url, String username, String password) async {
    // TODO: Support basic authentication
    Document htmlDocument = parse(utf8.decode(await http.readBytes(url)));

    List<Element> documentElements =
        htmlDocument.getElementsByTagName('a').where((Element element) {
      return element.attributes.containsKey('href') &&
          element.attributes['href'].endsWith('.pdf');
    }).toList();

    List<Map<String, dynamic>> documents = List();

    for (int i = 0; i < documentElements.length; ++i) {
      Element documentElement = documentElements[i];
      http.Response response =
          await http.head(documentElement.attributes['href']);

      print(response.reasonPhrase);
      if (response.reasonPhrase == 'OK') {
        assert(response.headers['content-type'] == 'application/pdf');
        assert(response.headers.containsKey('last-modified'));
      }

      documents.add({
        'url': documentElement.attributes['href'],
        'titleOnWebsite': documentElement.innerHtml.replaceAll('\n', '').trim(),
        'statusCodeReason': response.reasonPhrase,
        'lastModified': response.headers.containsKey('last-modified')
            ? HttpDate.parse(response.headers['last-modified']).toString()
            : null,
        'orderOnWebsite': i,
      });
    }

    return documents;
  }
}
