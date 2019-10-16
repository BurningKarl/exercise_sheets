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

class WrongCredentialsException implements Exception {}

class NetworkOperations {
  static Future<void> launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  factory NetworkOperations.forUrl(String baseUrl) {
    Uri url = Uri.parse(baseUrl);
    if (url.host.endsWith(EcampusNetworkOperations.HOST)) {
      return EcampusNetworkOperations(url);
    } else {
      return NetworkOperations(url);
    }
  }

  final Dio dio;
  final Uri baseUrl;

  NetworkOperations(this.baseUrl) : dio = Dio();

  Future<void> authenticate(String username, String password) async {
    // Add basic authentication
    dio.options.headers[HttpHeaders.authorizationHeader] =
        'Basic ' + base64Encode(utf8.encode('$username:$password'));
  }

  Future<void> addCookieManager() async {
    Directory cookieDirectory = await StorageOperations.cookieDirectory();
    cookieDirectory.create(recursive: true);
    dio.interceptors
        .add(CookieManager(PersistCookieJar(dir: cookieDirectory.path)));
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

  bool isPdfHeader(Response response) {
    String contentType =
        response.headers[HttpHeaders.contentTypeHeader]?.single;

    print(contentType);
    print(response.request.uri);
    return contentType == 'application/pdf' ||
        contentType == 'application/binary' &&
            response.request.uri.host.endsWith('dropbox.com');
  }

  Uri resolveRelativeReference(String relativeUrl) {
    Uri link = baseUrl.resolve(relativeUrl);
    if (link.host.endsWith('dropbox.com')) {
      link = link.replace(
        queryParameters: Map.from(link.queryParameters)..['dl'] = '1',
      );
    }
    return link;
  }

  void replaceRelativeReferences(Element element) {
    String relativeUrl = element.attributes['href'];
    element.attributes['href'] =
        resolveRelativeReference(relativeUrl).toString();
  }

  Future<Map<String, dynamic>> elementToDocument(
      MapEntry<int, Element> entry) async {
    Element element = entry.value;
    Response response = await head(element.attributes['href']);

    print(response.statusMessage);
    if (response.statusMessage == 'OK' && !isPdfHeader(response)) {
      response.statusMessage = 'Not a PDF';
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

  Future<List<Map<String, dynamic>>> retrieveDocumentMetadata() async {
    Document htmlDocument = parse(await read(baseUrl.toString()));

    List<Element> documentElements = htmlDocument.getElementsByTagName('a')
      ..retainWhere((element) => element.attributes.containsKey('href'))
      ..forEach(replaceRelativeReferences)
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
