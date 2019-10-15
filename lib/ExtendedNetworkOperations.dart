import 'dart:io';
import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:exercise_sheets/NetworkOperations.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;

class EcampusWrongCredentialsException extends WrongCredentialsException {}

class EcampusNetworkOperations extends NetworkOperations {
  // TODO: Implement recursive search for documents on Ecampus
  static const String HOST = 'ecampus.uni-bonn.de';
  static const String LOGIN_PAGE_URL =
      'https://ecampus.uni-bonn.de/login.php?cmd=force_login';

  EcampusNetworkOperations(Uri baseUrl) : super(baseUrl);

  Future<void> loginToEcampus(String username, String password) async {
    Document htmlDocument = parse(await read(LOGIN_PAGE_URL));
    Element loginForm = htmlDocument
        .getElementsByTagName('form')
        .singleWhere((element) => element.attributes['name'] == 'formlogin');

    Map<String, String> data = Map.fromEntries(loginForm
        .getElementsByTagName('input')
        .map((input) =>
            MapEntry(input.attributes['name'], input.attributes['value'])));

    data.addAll({'username': username, 'password': password});

    String relativeActionUrl = loginForm.attributes['action'];
    Uri actionUrl = Uri.parse(LOGIN_PAGE_URL).resolve(relativeActionUrl);

    Response response = await dio.post(actionUrl.toString(),
        data: data,
        options: Options(
          followRedirects: true,
          validateStatus: (status) => [200, 302].contains(status),
          contentType: 'application/x-www-form-urlencoded',
        ));

    String location = response.headers[HttpHeaders.locationHeader]?.single;
    if (location == null) {
      throw EcampusWrongCredentialsException();
    } else {
      print(location);
    }
  }

  Future<void> authenticate(String username, String password) async {
    await addCookieManager();
    print('Added cookie Manager');
    await loginToEcampus(username, password);
    print('Logged in to Ecampus');
  }

  Future<List<Map<String, dynamic>>> retrieveDocumentMetadata() async {
    Queue<String> folderUrls = Queue.from([baseUrl.toString()]);
    List<Element> documentElements = [];

    while (folderUrls.isNotEmpty) {
      String folderUrl = folderUrls.removeFirst();
      Document htmlDocument = parse(await read(folderUrl));
      print('Got htmlDocument at $folderUrl');

      var containers =
          htmlDocument.getElementsByClassName('ilContainerItemsContainer');
      if (containers.isEmpty) continue;
      Element container = containers.single;

      List<Element> linkElements =
          container.getElementsByClassName('il_ContainerItemTitle')
            ..retainWhere((element) => element.attributes.containsKey('href'))
            ..forEach(replaceRelativeReferences);

      folderUrls.addAll(linkElements
          .map((element) => element.attributes['href'])
          .where((url) => url.contains('fold')));

      documentElements.addAll(linkElements
          .where((element) => element.attributes['href'].contains('file')));

      print('folderUrls = $folderUrls');
      print('documentElements = $documentElements');
    }

    return await Future.wait(
        documentElements.asMap().entries.map(elementToDocument));
  }
}
