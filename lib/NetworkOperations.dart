import 'dart:convert';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:exercise_sheets/ExtendedNetworkOperations.dart';
import 'package:exercise_sheets/StorageOperations.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;
import 'package:url_launcher/url_launcher.dart';

class NetworkOperationsBase {
  final Dio dio;
  String username;
  String password;

  NetworkOperationsBase() : dio = Dio();

  void addAuthentication(String username, String password) {
    this.username = username;
    this.password = password;

    // Add basic authentication
    dio.options.headers[HttpHeaders.authorizationHeader] =
        'Basic ' + base64Encode(utf8.encode('$username:$password'));
  }

  Future<void> addCookieManager() async {
    dio.interceptors.add(CookieManager(CookieJar()));
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

  Uri resolveRelativeReference(Uri baseUrl, String relativeUrl) {
    return baseUrl.resolve(relativeUrl);
  }

  void replaceRelativeReferences(Element element, Uri baseUrl) {
    String relativeUrl = element.attributes['href'];
    element.attributes['href'] =
        resolveRelativeReference(baseUrl, relativeUrl).toString();
  }

  Future<Map<String, dynamic>> elementToDocument(
      MapEntry<int, Element> entry) async {
    Element element = entry.value;
    Response response = await head(element.attributes['href']);

    print(response.statusMessage);
    if (response.statusMessage == 'OK') {
      assert(['application/pdf', 'application/binary']
          .contains(response.headers[HttpHeaders.contentTypeHeader].single));
    }

    String lastModifiedDate =
        response.headers[HttpHeaders.lastModifiedHeader]?.single;
    return {
      'url': element.attributes['href'],
      'titleOnWebsite': element.innerHtml.replaceAll('\n', '').trim(),
      'statusMessage': response.statusMessage,
      'lastModified': lastModifiedDate != null
          ? HttpDate.parse(lastModifiedDate).toUtc().toString()
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

class NetworkOperations extends NetworkOperationsBase
    with DropboxNetworkOperations, EcampusNetworkOperations {
  static Future<void> launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
