import 'dart:io';
import 'package:dio/dio.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';
import 'package:url_launcher/url_launcher.dart';

class NetworkOperations {
  static bool isPdfHyperlink(Element element) {
    return element.attributes.containsKey('href') &&
        element.attributes['href'].endsWith('.pdf');
  }

  static Future<String> read(String url) async {
    return (await Dio().get(url)).data.toString();
  }

  static Future<Response> head(String url) {
    return Dio().head(url, options: Options(validateStatus: (status) => true));
  }

  static Future<Map<String, dynamic>> elementToDocument(
      MapEntry<int, Element> entry) async {
    Element element = entry.value;
    Response response = await head(element.attributes['href']);

    print(response.statusMessage);
    if (response.statusMessage == 'OK') {
      assert(response.headers['content-type'].single == 'application/pdf');
      assert(response.headers['last-modified'].length == 1);
    }

    return {
      'url': element.attributes['href'],
      'titleOnWebsite': element.innerHtml.replaceAll('\n', '').trim(),
      'statusCodeReason': response.statusMessage,
      'lastModified': response.headers['last-modified'] != null
          ? HttpDate.parse(response.headers['last-modified'].single).toString()
          : null,
      'orderOnWebsite': entry.key,
    };
  }

  static Future<List<Map<String, dynamic>>> retrieveDocumentMetadata(
      String url, String username, String password) async {
    // TODO: Support basic authentication
    Document htmlDocument = parse(await read(url));

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
