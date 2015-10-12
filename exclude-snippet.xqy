xquery version "1.0-ml";

(:~
 : A snippeting function that excludes elements or JSON properties by name
 :
 : @author Joe Bryan
 :)

module namespace snip = "http://marklogic.com/exclude-snippet";

import module namespace search = "http://marklogic.com/appservices/search"
  at "/MarkLogic/appservices/search/search.xqy";
import module namespace search-impl = "http://marklogic.com/appservices/search-impl"
  at "/MarkLogic/appservices/search/search-impl.xqy";

declare option xdmp:mapping "false";

(:~ reconstruct a JSON node, excluding properties by name :)
declare %private function snip:exclude-json($x as item(), $excluded as xs:string*)
{
  typeswitch($x)
  case document-node() return
    snip:exclude-json($x/node(), $excluded)
  case object-node()|array-node() return
    xdmp:to-json(
      snip:exclude-json(xdmp:from-json($x), $excluded))
  case json:array return
    (: TODO: preserve null / sparse arrays :)
    for $val in json:array-values($x)
    return snip:exclude-json($val, $excluded)
  case json:object return
    (: TODO: preserve property order :)
    map:new((
      for $key in map:keys($x)
      return
        if ($key = $excluded) then ()
        else
          map:entry($key,
            snip:exclude-json(map:get($x, $key), $excluded))))
  default return $x
};

(:~ reconstruct an XML node, excluding properties by QName :)
declare %private function snip:exclude-element($x as item(), $excluded as xs:QName*)
{
  typeswitch($x)
  case document-node() return
    snip:exclude-element($x/node(), $excluded)
  case element() return
    if (fn:node-name($x) = $excluded) then ()
    else
      element { fn:node-name($x) } {
        $x/@*,
        $x/node() ! snip:exclude-element(., $excluded)
      }
  default return $x
};

(:~
 : reconstruct a node, excluding elements or JSON properties by name,
 : as specified in <search:transform-results/> options:
 :
 :  <code>
 :  &lt;transform-results apply="snippet"
 :                     ns="http://marklogic.com/exclude-snippet"
 :                     at="/ext/mlpm_modules/ml-snippeting/exclude-snippet.xqy">
 :    &lt;excluded-matches>
 :      &lt;json-property>json-secret&lt;/json-property>
 :      &lt;element ns="http://domain.com/ns" name="xml-secret"/>
 :    &lt;/excluded-matches>
 :  &lt;/transform-results>
 : </code>
 :)
declare %private function snip:process-excludes(
  $x as node(),
  $options as element(search:transform-results)?
)
{
  if (fn:exists($x/(self::object-node()|self::array-node()|
                    child::object-node()|child::array-node())))
  then
    snip:exclude-json($x,
      $options/search:excluded-matches/search:json-property/fn:string())
  else
    snip:exclude-element($x,
      $options/(search:excluded-elements|search:excluded-matches)
        /search:element/search-impl:spec-qname(.))
};

declare function snip:snippet(
  $result as node()?,
  $ctsquery as schema-element(cts:query),
  $options as element(search:transform-results)?
) as element(search:snippet)
{
  search:snippet(
    snip:process-excludes($result, $options),
    $ctsquery,
    $options
  )
};
