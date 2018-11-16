xquery version "1.0-ml";

module namespace ro="http://travelmap.nwalsh.com/ns/ro";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace rest = "http://marklogic.com/appservices/rest"
       at "/MarkLogic/appservices/utils/rest.xqy";

declare variable $ro:OPTIONS :=
<rest:options>
  <rest:request uri="^/$"
                endpoint="/default.xqy"
                user-params="forbid">
  </rest:request>
  <rest:request uri="^/map$"
                endpoint="/map.xqy"
                user-params="forbid">
    <rest:http method="GET"/>
    <rest:http method="POST"/>
    <rest:param name="routes"/>
    <rest:param name="input" as="boolean" default="false"/>
    <rest:param name="width" default="800px"/>
    <rest:param name="height" default="600px"/>
  </rest:request>
  <rest:request uri="^/near$"
                endpoint="/near.xqy"
                user-params="forbid">
    <rest:param name="lat" as="decimal"/>
    <rest:param name="lng" as="decimal"/>
  </rest:request>
</rest:options>;
