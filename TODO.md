# Overview

### Frontend

The app has three different screens/pages:

1. Website selection
2. Document selection
3. Detailed document view

### Backend

The app needs to store metadata about the websites and documents using a database (`sqflite`). Two
tables are necessary:

1. 'websites' with columns: id, name, url, defaultMaximumPoints, username, password
2. 'documents' with columens: id, website_id, name, url, points, maximumPoints

The app also downloads all documents to the local storage (`localstorage`)

# TODO

* Split up the code into different files
* Create the databases and fill them with testing data
* Build the front end using a new class for every page
* Add dialogs for adding new websites and modifying existing ones
* Fill the documents table with data from the internet
* Download the PDF files from the sites
* Export functionality for the document metadata (incl. points)
