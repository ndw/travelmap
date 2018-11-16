xquery version "1.0-ml";

import module namespace rest="http://marklogic.com/appservices/rest"
       at "/MarkLogic/appservices/utils/rest.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace air="http://nwalsh.com/ns/airports";

declare option xdmp:mapping "false";

declare variable $noiata := cts:element-value-query(xs:QName("air:iata_code"), "");

declare function local:find-radius(
  $center as cts:point
) as xs:float
{
  let $radius := local:find-radius($center, 0, 100, 20)
  return
    $radius
};

declare function local:find-radius(
  $center as cts:point,
  $minr   as xs:float,
  $radius as xs:float,
  $iter   as xs:integer
) as xs:float
{
  let $q := cts:element-pair-geospatial-query(
                xs:QName("air:airport"),
                xs:QName("air:latitude_deg"),
                xs:QName("air:longitude_deg"),
                cts:circle($radius, $center))
  let $count := xdmp:estimate(cts:search(/air:airport, cts:and-not-query($q, $noiata)))
  return
    if ($iter <= 0 or $count = 10)
    then
      $radius
    else
      if ($count > 10)
      then
        local:find-radius($center, $minr, $minr + (($radius - $minr) div 2.0), $iter - 1)
      else
        let $newr := if ($count = 0) then $radius * 2 else $radius + (($radius - $minr) div 2.0)
        return
          local:find-radius($center, $radius, $newr, $iter - 1)
};

let $request   := <rest:request uri="^/near$"
                                endpoint="/near.xqy"
                                user-params="forbid">
                    <rest:http method="GET"/>
                    <rest:param name="lat" required="true" as="decimal"/>
                    <rest:param name="lng" required="true" as="decimal"/>
                  </rest:request>
let $params    := rest:process-request($request)

let $lat       := map:get($params, "lat")
let $lng       := map:get($params, "lng")
let $center    := cts:point($lat, $lng)
let $radius    := local:find-radius($center)
let $withinr   := cts:element-pair-geospatial-query(
                      xs:QName("air:airport"),
                      xs:QName("air:latitude_deg"),
                      xs:QName("air:longitude_deg"),
                      cts:circle($radius, $center))
let $airports := cts:search(/air:airport,
                   cts:and-not-query($withinr, $noiata))
return
  concat("[",
    string-join(for $airport in $airports
                let $pt := cts:point(xs:decimal($airport/air:latitude_deg),
                                     xs:decimal($airport/air:longitude_deg))
                let $dist := round(cts:distance($center,$pt))
                order by $dist
                return
                  concat("{&quot;code&quot;: &quot;", $airport/air:iata_code, "&quot;,",
                         "&quot;name&quot;: &quot;", $airport/air:name, "&quot;,",
                         "&quot;lat&quot;: &quot;", $airport/air:latitude_deg, "&quot;,",
                         "&quot;lng&quot;: &quot;", $airport/air:longitude_deg, "&quot;,",
                         "&quot;dist&quot;: &quot;", $dist, "&quot;",
                         "}"),
                ",&#10;"),
    "]")


