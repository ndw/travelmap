# Travel map app

These are the sources for the [travel map app](http://travelmap.nwalsh.com/).

## Requirements

This travel map application runs on
[MarkLogic 5](http://www.marklogic.com/product/marklogic-server.html) (or later). You can
run it on an earlier release if you download and install
the
[REST API Library](https://github.com/marklogic/ml-rest-lib).

## Setup

FIXME: add some more detail here

1. Create a database and app server for the application.
2. Point the app server root at this repository.
3. Load the data (see below). The data comes from [OurAirports](http://ourairports.com).
4. Point your browser at the app server and you should be ready to go!

## Load the data

I loaded the data in QueryConsole:

    xquery version "1.0-ml";

    declare default function namespace "http://www.w3.org/2005/xpath-functions";

    declare namespace air="http://nwalsh.com/ns/airports";

    declare option xdmp:mapping "false";

    let $airports := xdmp:document-get("/MarkLogic/travelmap/etc/airports.xml")/air:airports
    let $load := for $airport in $airports/air:airport
                 let $uri := concat("/airports/", $airport/air:id, ".xml")
                 return
                   xdmp:document-insert($uri, $airport)
    return
      concat("Loaded ", count($airports/air:airport), " airports.");

Change the `xdmp:document-get` path as necessary to point to the `airports.xml` data.

Depending on how you setup the security on the server, you may need to add read
privileges to the documents that you insert.

## Questions or problems

Let [norm](mailto:ndw@nwalsh.com) know.
