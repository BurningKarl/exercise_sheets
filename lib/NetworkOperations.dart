import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';
import 'package:url_launcher/url_launcher.dart';

class NetworkOperations {
  static bool isPdfHyperlink(Element element) {
    return element.attributes.containsKey('href') &&
        element.attributes['href'].endsWith('.pdf');
  }

  static Future<Map<String, dynamic>> elementToDocument(
      MapEntry<int, Element> entry) async {
    Element element = entry.value;
    http.Response response = await http.head(element.attributes['href']);

    print(response.reasonPhrase);
    if (response.reasonPhrase == 'OK') {
      assert(response.headers['content-type'] == 'application/pdf');
      assert(response.headers.containsKey('last-modified'));
    }

    return {
      'url': element.attributes['href'],
      'titleOnWebsite': element.innerHtml.replaceAll('\n', '').trim(),
      'statusCodeReason': response.reasonPhrase,
      'lastModified': response.headers.containsKey('last-modified')
          ? HttpDate.parse(response.headers['last-modified']).toString()
          : null,
      'orderOnWebsite': entry.key,
    };
  }

  static Future<List<Map<String, dynamic>>> retrieveDocumentMetadata(
      String url, String username, String password) async {
    // TODO: Support basic authentication
    // TODO: Check how to get the correct charset
//    Document htmlDocument = parse(utf8.decode(await http.readBytes(url)));
    Document htmlDocument = parse(await http.read(url));

    List<Element> documentElements =
        htmlDocument.getElementsByTagName('a').where(isPdfHyperlink).toList();

    return await Future.wait(
        documentElements.asMap().entries.map(elementToDocument));
  }

  static Future<void> launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
