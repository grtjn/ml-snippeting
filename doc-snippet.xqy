xquery version "1.0-ml";

module namespace snip = "http://marklogic.com/doc-snippet";

import module namespace search = "http://marklogic.com/appservices/search"
  at "/MarkLogic/appservices/search/search.xqy";

declare option xdmp:mapping "false";

declare function snip:snippet(
  $result as node()?,
  $ctsquery as schema-element(cts:query),
  $options as element(search:transform-results)?
) as element(search:snippet) {
  search:snippet(
    text { $result//text() },
    $ctsquery,
    $options
  )
};