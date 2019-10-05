import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:exercise_sheets/StorageOperations.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';
import 'package:url_launcher/url_launcher.dart';

class NetworkOperations {
  static basicAuthentication(String username, String password) {
    return 'Basic ' + base64Encode(utf8.encode('$username:$password'));
  }

  static Future<void> launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  static void replaceRelativeReferences(Element element, Uri baseUrl) {
    Uri link = baseUrl.resolve(element.attributes['href']);
    if (link.host.endsWith('dropbox.com')) {
      link = link.replace(
        queryParameters: Map.from(link.queryParameters)..['dl'] = '1',
      );
    }
    element.attributes['href'] = link.toString();
  }

  // Member functions because they all use the same Dio
  final Dio dio;

  NetworkOperations([Dio dio]) : dio = dio ?? Dio();

  static withAuthentication(String username, String password) {
    return NetworkOperations(Dio(BaseOptions(
      headers: {'authorization': basicAuthentication(username, password)},
    )));
  }

  Future<String> read(String url) async {
    return (await dio.get(url)).data.toString();
  }

  Future<Response> head(String url) {
    return dio.head(url, options: Options(validateStatus: (status) => true));
  }

  Future<Response> download(String url, String savePath) {
    return dio.download(url, savePath);
  }

  Future<Map<String, dynamic>> elementToDocument(
      MapEntry<int, Element> entry) async {
    Element element = entry.value;
    Response response = await head(element.attributes['href']);

    print(response.statusMessage);
    if (response.statusMessage == 'OK') {
      assert(['application/pdf', 'application/binary']
          .contains(response.headers['content-type'].single));
    }

    return {
      'url': element.attributes['href'],
      'titleOnWebsite': element.innerHtml.replaceAll('\n', '').trim(),
      'statusMessage': response.statusMessage,
      'lastModified': response.headers['last-modified'] != null
          ? HttpDate.parse(response.headers['last-modified'].single).toString()
          : null,
      'orderOnWebsite': entry.key,
    };
  }

  Future<List<Map<String, dynamic>>> retrieveDocumentMetadata(
      String url) async {
    Uri baseUrl = Uri.parse(url);
    Document htmlDocument = parse(await read(url));

    List<Element> documentElements = htmlDocument.getElementsByTagName('a')
      ..retainWhere((element) => element.attributes.containsKey('href'))
      ..forEach((element) => replaceRelativeReferences(element, baseUrl))
      ..retainWhere((element) =>
          Uri.parse(element.attributes['href']).path.endsWith('.pdf'));

    return await Future.wait(
        documentElements.asMap().entries.map(elementToDocument));
  }

  Future<MapEntry<int, File>> downloadDocumentPdf(
      Map<String, dynamic> document) async {
    String fileName = Uri.parse(document['url']).pathSegments.last;
    File file = await StorageOperations.documentToPdfFile(document, fileName);
    print(file.path);
    await file.create(recursive: true);
    await download(document['url'], file.path);
    return MapEntry(document['id'], file);
  }
}
