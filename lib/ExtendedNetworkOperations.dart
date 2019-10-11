import 'dart:io';

import 'package:dio/dio.dart';
import 'package:exercise_sheets/NetworkOperations.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

mixin DropboxNetworkOperations on NetworkOperationsBase {
  Uri resolveRelativeReference(Uri baseUrl, String relativeUrl) {
    Uri link = super.resolveRelativeReference(baseUrl, relativeUrl);
    if (link.host.endsWith('dropbox.com')) {
      link = link.replace(
        queryParameters: Map.from(link.queryParameters)..['dl'] = '1',
      );
    }
    return link;
  }
}

mixin EcampusNetworkOperations on NetworkOperationsBase {
  // TODO: Implement recursive search for documents on Ecampus
  static const String LOGIN_PAGE_URL = 'https://ecampus.uni-bonn.de/login.php?target=crs_1537926&cmd=force_login&lang=de';

  Future<void> loginToEcampus() async {
    Document htmlDocument = parse(await read(LOGIN_PAGE_URL));
    Element loginForm = htmlDocument
        .getElementsByTagName('form')
        .singleWhere((element) => element.attributes['name'] == 'formlogin');

    Map<String, String> data = Map.fromEntries(loginForm
        .getElementsByTagName('input')
        .map((input) =>
            MapEntry(input.attributes['name'], input.attributes['value'])));

    data.addAll({'username': username, 'password': password});

    Uri actionUrl = resolveRelativeReference(
      Uri.parse(LOGIN_PAGE_URL),
      loginForm.attributes['action'],
    );

    Response response = await dio.post(actionUrl.toString(),
        data: data,
        options: Options(
          followRedirects: true,
          validateStatus: (status) => [200, 302].contains(status),
          contentType: 'application/x-www-form-urlencoded',
        ));
    print(response.headers[HttpHeaders.locationHeader]?.single);

    // TODO: Check which part of the login fails with incorrect credentials
    // and provide the user with more meaningful error messages

//    if (response.statusCode == HttpStatus.found) {
//      Response response2 =
//          await dio.get(response.headers[HttpHeaders.locationHeader].single);
//      print(response2.request.headers);
//      print(response2.redirects.single.location);
//      print(response2.data);
//    }
  }

  Future<List<Map<String, dynamic>>> retrieveDocumentMetadata(
      String url) async {
    Uri baseUrl = Uri.parse(url);
    if (baseUrl.host == 'ecampus.uni-bonn.de') {
      print('Special ecampus code');
      await addCookieManager();
      print('Added cookie manager');
      await loginToEcampus();
      print('Login successful');

//      Response response = await dio.get(url);
//      print(response.request.headers);
//      print(response.redirects.first.location);
      Document htmlDocument = parse(await read(url));

      Element container = htmlDocument
          .getElementsByClassName('ilContainerItemsContainer')
          .single;

      List<Element> documentElements = container.getElementsByClassName(
          'il_ContainerItemTitle')
        ..retainWhere((element) => element.attributes.containsKey('href'))
        ..forEach((element) => replaceRelativeReferences(element, baseUrl))
        ..retainWhere((element) => element.attributes['href'].contains('file'));

      return await Future.wait(
          documentElements.asMap().entries.map(elementToDocument));
    } else {
      return super.retrieveDocumentMetadata(url);
    }
  }
}
