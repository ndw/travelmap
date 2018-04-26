xquery version "1.0-ml";

import module namespace rest="http://marklogic.com/appservices/rest"
       at "/MarkLogic/appservices/utils/rest.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace air="http://nwalsh.com/ns/airports";

declare option xdmp:mapping "false";

<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>Travel map</title>
    <style type="text/css">
body {{ width: 640px;
        background-image: url("img/travelmap.gif");
        background-repeat: no-repeat;
     }}
    </style>
  </head>
  <body>
  <h1>Travel map</h1>
  <p>Welcome to <a href="https://nwalsh.com/">norm</a>'s travel map app.</p>
  <p>Enter a set of flights (for example, IAD-ORD,ORD-SFO,SFO-IAD):</p>
  <form action="/map" method="get">
    <input type="hidden" name="input" value="true"/>
    <textarea name="routes" rows="4" cols="80">
    </textarea>
    <br/>
    <input type="submit" value="Plot"/>
  </form>
  <p>If you flew the same leg more than once, enter it more than once. For
  example, two round trips from Washington D.C. to San Francisco:
  IAD-SFO,SFO-IAD,IAD-SFO,SFO-IAD
  </p>
  <p>Airport data graciously provided by <a href="http://ourairports.com">OurAirports</a>.
  </p>
  </body>
</html>
