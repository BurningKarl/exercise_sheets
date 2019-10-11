import 'package:exercise_sheets/NetworkOperations.dart';

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
}
