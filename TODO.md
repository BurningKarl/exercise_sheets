# Overview

### Frontend

The app has four different screens/pages:

1. Website selection
2. Document selection
3. Detailed document view
4. Settings for a website

### Backend

The app needs to store metadata about the websites and documents using a database (`sqflite`). Two
tables are necessary:

1. 'websites' with columns: `id`, `title`, `url`, `maximumPoints`, `username`, `password`, `showArchived`
2. 'documents' with columns: `id`, `websiteId`, `url`, `title`, `titleOnWebsite`, `statusMessage`, `lastModified`, `fileLastModified`, `orderOnWebsite`, `archived`, `pinned`, `points`, `maximumPoints`

The app also downloads all documents to the device.

# TODO

* Support different languages
* Export functionality for the document metadata (incl. points)
