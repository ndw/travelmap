xquery version "1.0-ml";

import module namespace rest="http://marklogic.com/appservices/rest"
       at "/MarkLogic/appservices/utils/rest.xqy";

import module namespace ro="http://travelmap.nwalsh.com/ns/ro"
       at "restopts.xqy";

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

let $request := $ro:OPTIONS/rest:request[@endpoint='/map.xqy']
let $params  := rest:process-request($request)
let $routes  := map:get($params, "routes")
let $routes := tokenize($routes, "\s*,\s*")
let $data   := for $route in $routes
               return
                 local:add-to-map($route)

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

return
(xdmp:set-response-content-type("text/html"),
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>Travel map</title>
    <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.6.1/jquery.min.js"
            type="text/javascript">
    </script>
    <script type="text/javascript" src="http://maps.google.com/maps/api/js?sensor=false">
    </script>
    <script src="js/TravelMap.js" type="text/javascript">
    </script>
  </head>
  <body>
    <div id="routemap" class="itingrp">
      <div class="artwork" id="flightmap" style="width: {$width}; height: {$height};"></div>
      <script type="text/javascript">
$(document).ready(function() {{
  mapDiv = document.getElementById('flightmap');
  { let $codes := string-join(distinct-values($data/air:iata_code/string()), ",")
    return
      if ($codes = "")
      then
        ()
      else
        concat("var ", $codes, ";&#10;")
  }
  { for $iata in distinct-values($data/air:iata_code/string())
    let $airport := ($data[air:iata_code = $iata])[1]
    let $lat := xs:decimal($airport/air:latitude_deg)
    let $long := xs:decimal($airport/air:longitude_deg)
    return
      concat("   ", $iata, " = new Airport(", $lat, ", ", $long,
             ", &quot;", $iata, "&quot;);&#10;")
  }
  { for $pair in distinct-values($data[self::air:route]/string())
    return
      concat("flights.push(new Flight(", $pair, "));&#10;")
  }
  Plot();
}});</script>
    </div>
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
</html>
)