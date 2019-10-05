import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:exercise_sheets/DocumentItem.dart';
import 'package:exercise_sheets/DatabaseState.dart';
import 'package:exercise_sheets/WebsiteInfoPage.dart';

class SelectedDocuments extends DelegatingList<int> with ChangeNotifier {
  SelectedDocuments(List<int> base) : super(base);

  void clear() {
    super.clear();
    notifyListeners();
  }

  bool isSelected(int documentId) {
    return contains(documentId);
  }

  bool inSelectionMode() {
    return isNotEmpty;
  }

  void toggleSelection(int documentId) {
    if (contains(documentId)) {
      remove(documentId);
    } else {
      add(documentId);
    }
    notifyListeners();
  }
}

enum DocumentSelectionPageActions { show_hide_archived }

class DocumentSelectionPage extends StatefulWidget {
  final int websiteId;

  const DocumentSelectionPage(this.websiteId);

  @override
  State<StatefulWidget> createState() => DocumentSelectionPageState(websiteId);
}

class DocumentSelectionPageState extends State<DocumentSelectionPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  final int websiteId;
  final SelectedDocuments selectedDocuments = SelectedDocuments([]);
  bool updatePdfsOnRefresh = false;

  DocumentSelectionPageState(this.websiteId);

  int negate(int value) {
    if (value == 0) {
      return 1;
    } else {
      return 0;
    }
  }

  void showSnackBar(String content) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(content),
    ));
  }

  bool isPdfUpdateNecessary(DatabaseState databaseState) {
    return databaseState
        .websiteIdToDocuments(websiteId)
        .any(databaseState.isPdfUpdateNecessary);
  }

  void handleNetworkError(dynamic error, BuildContext context) {
    print('Network error: $error');
    String errorText;
    if (error is DioError && error.type == DioErrorType.DEFAULT) {
      errorText = 'No network connection available';
    } else {
      errorText = 'A network error occured: \n$error';
    }
    showSnackBar(errorText);
  }

  Future<void> handleRefresh(DatabaseState databaseState) async {
    print('handleRefresh: updatePdfsOnRefresh=$updatePdfsOnRefresh');
    if (!updatePdfsOnRefresh) {
      await databaseState
          .updateDocumentMetadata(websiteId)
          .then((numberOfUpdates) {
        showSnackBar('Successfully scanned the website and updated '
            '$numberOfUpdates documents');
      }).catchError((error) => handleNetworkError(error, context));
    } else if (isPdfUpdateNecessary(databaseState)) {
      databaseState.updateDocumentPdfs(websiteId).then((numberOfUpdates) {
        showSnackBar('Successfully updated $numberOfUpdates PDFs');
      }).catchError((error) => handleNetworkError(error, context));
    } else {
      databaseState
          .updateDocumentPdfs(websiteId, forceUpdate: true)
          .then((numberOfUpdates) {
        showSnackBar('Successfully updated $numberOfUpdates PDFs');
      }).catchError((error) => handleNetworkError(error, context));
    }
    updatePdfsOnRefresh = false;
  }

  Future<void> archiveDocuments(
      List<int> toBeArchived, DatabaseState databaseState) async {
    var documents = toBeArchived
        .map((documentId) => databaseState.documentIdToDocument(documentId));

    var updates = Map.fromEntries(documents.map((document) {
      return MapEntry(document['id'] as int, {
        'archived': negate(document['archived']),
      });
    }));

    databaseState.updateDocuments(updates);

    for (var document in documents) {
      print('Archived website ${document['title']} with id ${document['id']}');
    }
  }

  Future<void> pinDocuments(
      List<int> toBePinned, DatabaseState databaseState) async {
    var documents = toBePinned
        .map((documentId) => databaseState.documentIdToDocument(documentId));

    var updates = Map.fromEntries(documents.map((document) {
      return MapEntry(document['id'] as int, {
        'pinned': negate(document['pinned']),
      });
    }));

    databaseState.updateDocuments(updates);

    for (var document in documents) {
      print('Pinned website ${document['title']} with id ${document['id']}');
    }
  }

  Widget buildContent(BuildContext context, DatabaseState databaseState) {
    Map<String, dynamic> website = databaseState.websiteIdToWebsite(websiteId);
    List<Map<String, dynamic>> documents =
        databaseState.websiteIdToDocuments(websiteId);

    if (website['showArchived'] == 0) {
      // Show only those document that are not archived
      documents.retainWhere((document) => document['archived'] == 0);
    }

    if (databaseState.databaseError) {
      return Center(
        child: Text('The database could not be opened'),
      );
    }
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: () => handleRefresh(databaseState),
      child: Scrollbar(
        child: ChangeNotifierProvider<SelectedDocuments>.value(
          value: selectedDocuments,
          child: ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, int index) {
              Map<String, dynamic> document = documents[index];

              return DocumentItem(
                document: document,
                onToggleSelection: () {
                  setState(() {
                    selectedDocuments.toggleSelection(document['id']);
                  });
                },
                enableDismiss: website['showArchived'] == 0,
                onArchived: (_) =>
                    archiveDocuments([document['id']], databaseState),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseState>(builder: (context, databaseState, _) {
      Map<String, dynamic> website =
          databaseState.websiteIdToWebsite(websiteId);

      AppBar appBar;
      if (selectedDocuments.inSelectionMode()) {
        appBar = AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                selectedDocuments.clear();
              });
            },
          ),
          title: Text(selectedDocuments.length.toString()),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.archive),
              onPressed: () async {
                await archiveDocuments(selectedDocuments, databaseState);
                setState(() {
                  selectedDocuments.clear();
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.star),
              onPressed: () async {
                await pinDocuments(selectedDocuments, databaseState);
                setState(() {
                  selectedDocuments.clear();
                });
              },
            ),
          ],
        );
      } else {
        appBar = AppBar(
          title: Text(website['title']),
          actions: <Widget>[
            IconButton(
              icon: Icon(isPdfUpdateNecessary(databaseState)
                  ? Icons.cloud_download
                  : Icons.cloud_done),
              tooltip: 'Download PDFs',
              onPressed: () async {
                updatePdfsOnRefresh = true;
                await _refreshIndicatorKey.currentState.show();
              },
            ),
            IconButton(
              icon: Icon(Icons.settings),
              tooltip: 'Settings',
              onPressed: () {
                print('Opened settings for website ${website['title']} '
                    'with id ${website['id']}');

                Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => WebsiteInfoPage(websiteId),
                    ));
              },
            ),
            PopupMenuButton<DocumentSelectionPageActions>(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: DocumentSelectionPageActions.show_hide_archived,
                  child: Text(website['showArchived'] == 0
                      ? 'Show archived documents'
                      : 'Hide archived documents'),
                )
              ],
              onSelected: (DocumentSelectionPageActions value) {
                if (value == DocumentSelectionPageActions.show_hide_archived) {
                  databaseState.updateWebsite(website['id'], {
                    'showArchived': negate(website['showArchived']),
                  });
                }
              },
            )
          ],
        );
      }

      return Scaffold(
        key: _scaffoldKey,
        appBar: appBar,
        body: buildContent(context, databaseState),
      );
    });
  }
}
