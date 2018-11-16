xquery version "1.0-ml";

import module namespace rest="http://marklogic.com/appservices/rest"
       at "/MarkLogic/appservices/utils/rest.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace air="http://nwalsh.com/ns/airports";

declare option xdmp:mapping "false";

declare function local:airport(
  $code as xs:string
) as element()
{
  let $code := upper-case(normalize-space($code))
  let $airport := (/air:airport[air:iata_code = $code])[1]
  return
  if (exists($airport))
  then
    $airport
  else
    <air:error>
      { concat("'", $code, "' is not a recognized airport (IATA) code.") }
    </air:error>
};

declare function local:add-to-map(
  $route as xs:string
) as element()*
{
  let $dep := local:airport(substring-before($route, "-"))
  let $arr := local:airport(substring-after($route, "-"))
  return
    ($dep, $arr,
     if ($dep/self::air:error or $arr/self::air:error)
     then ()
     else <air:route>{string($dep/air:iata_code)},{string($arr/air:iata_code)}</air:route>)
};

let $params   := map:map()
let $_        := map:put($params, "routes", xdmp:get-request-field("routes"))
let $_        := map:put($params, "input", xdmp:get-request-field("input"))
let $_        := map:put($params, "width",
                   if (xdmp:get-request-field("width"))
                   then xdmp:get-request-field("width")
                   else "100%")
let $_        := map:put($params, "height",
                   if (xdmp:get-request-field("height"))
                   then xdmp:get-request-field("height")
                   else "65%")

let $_ := xdmp:log($params)

let $routes   := map:get($params, "routes")
let $routes   := tokenize($routes, "\s*,\s*")
let $data     := for $route in $routes
                 return
                   local:add-to-map($route)
let $iata     := distinct-values($data[self::air:airport]/air:iata_code/data())
let $airports := for $code in $iata
                 return ($data[self::air:airport][air:iata_code=$code])[1]
let $airports := for $airport in $airports
                 order by $airport/air:name
                 return $airport

let $miles  := for $pair in $data/self::air:route/string()
               let $dep := substring-before($pair,",")
               let $airport := ($data[air:iata_code = $dep])[1]
               let $lat := xs:decimal($airport/air:latitude_deg)
               let $long := xs:decimal($airport/air:longitude_deg)
               let $depgeo := cts:point($lat, $long)

               let $arr := substring-after($pair,",")
               let $airport := ($data[air:iata_code = $arr])[1]
               let $lat := xs:decimal($airport/air:latitude_deg)
               let $long := xs:decimal($airport/air:longitude_deg)
               let $arrgeo := cts:point($lat, $long)
               return
                 cts:distance($depgeo, $arrgeo)

let $dist   := sum($miles)
let $width  := map:get($params, "width")
let $height := map:get($params, "height")

let $_ := xdmp:log(("w",$width,"h",$height))

return
(xdmp:set-response-content-type("text/html"),
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta charset="utf-8" />
    <title>Travel map</title>
    <link rel="stylesheet" type="text/css" href="/css/travelmap.css" />
    <script type="text/javascript" src="/js/jquery-3.1.1.min.js"/>
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.3.1/dist/leaflet.css"
          integrity="sha512-Rksm5RenBEKSKFjgI3a41vrjkw4EVPlJ3+OiI65vTjIdo9brlAacEuKOiQ5OFh7cOI1bkDwLqdLw3Zg0cRJAAQ=="
          crossorigin=""/>
  </head>
  <body>
    <div id="routemap" class="itingrp">
      <div class="artwork" id="flightmap" style="width: {$width}; height: {$height};"></div>
    </div>
    <ul>
      { for $airport in $airports
        return
          <li x-latitude="{$airport/air:latitude_deg}" x-longitude="{$airport/air:longitude_deg}"
              id="{$airport/air:iata_code}" class="airport">
            <span>{string($airport/air:name)}</span>
          </li>
      }
      { for $route in $data[self::air:route]
        let $dep := local:airport(substring-before($route, ","))
        let $arr := local:airport(substring-after($route, ","))

        let $lat := xs:decimal($dep/air:latitude_deg)
        let $long := xs:decimal($dep/air:longitude_deg)
        let $depgeo := cts:point($lat, $long)

        let $lat := xs:decimal($arr/air:latitude_deg)
        let $long := xs:decimal($arr/air:longitude_deg)
        let $arrgeo := cts:point($lat, $long)

        let $dist := cts:distance($depgeo, $arrgeo)
        return
          <li x-depart="{$dep/air:iata_code}" x-arrive="{$arr/air:iata_code}"
              class="route">
            <span class="iata">{string($dep/air:iata_code)}-{string($arr/air:iata_code)}</span>
            { ", " }
            <span class="miles">{round($dist)} miles</span>
          </li>
      }
    </ul>
    <p>
      { round($dist) } miles in
      { count($routes) } legs along { count(distinct-values($data[self::air:route]/string())) }
      routes between { count(distinct-values($data/air:iata_code/string())) }
      airports.
    </p>

    { if (empty($routes) or map:get($params, "input"))
      then
        (<input type="hidden" id="travelmapclickable" value="true"/>,
         <form action="/map" method="get">
           <textarea name="routes" rows="4" cols="80">
             { map:get($params, "routes") }
           </textarea>
           <br/>
           <input type="submit" value="Update"/>
           <input type="checkbox" name="input" value="true" checked="checked"/>
           Show input form
         </form>)
      else
        ()
    }

    { if ($data/self::air:error)
      then
        <p class="error" xmlns="http://www.w3.org/1999/xhtml">
          { for $err in distinct-values($data/self::air:error/string())
            return
              ($err, <br xmlns="http://www.w3.org/1999/xhtml"/>)
          }
        </p>
      else
        ()
    }

    <div id="near">
      { if (empty($routes) or map:get($params, "input"))
        then
          "(You can click the map to find more airport codes)"
        else
          ()
      }
    </div>
  </body>
  <script src="https://unpkg.com/leaflet@1.3.1/dist/leaflet.js"
          integrity="sha512-/Nsx9X4HebavoBvEBuyp3I7od5tA0UzAxs+j83KgC8PU0kgB4XiK4Lfe4y4cgBtaRJQEIFCW+oC506aPT2L1zw=="
          crossorigin=""/>
  <script src="/js/Leaflet.Geodesic.js"/>
  <script src="/js/Leaflet.MakiMarkers.js"/>
  <script src="/js/openstreet.js"/>
</html>
)