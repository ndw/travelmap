xquery version "1.0-ml";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace rest="http://marklogic.com/appservices/rest"
       at "/MarkLogic/appservices/utils/rest.xqy";

import module namespace ro="http://travelmap.nwalsh.com/ns/ro"
       at "restopts.xqy";

let $ruri := xdmp:get-request-url()
let $uri  := if (contains($ruri, "?")) then substring-before($ruri, "?") else $ruri
return
  if ($uri = "/js/TravelMap.js"
      or $uri = "/img/travelmap.gif"
      or $uri = "/img/x.png")
  then
    $uri
  else
    let $new := rest:rewrite($ro:OPTIONS)
    return
      if (empty($new))
      then
        (xdmp:set-response-code(404, "404 File Not Found"), "/404.html")
      else
        $new
