xquery version "1.0-ml";

module namespace snip = "http://marklogic.com/attribute-snippet";

import module namespace search = "http://marklogic.com/appservices/search"
  at "/MarkLogic/appservices/search/search.xqy";

declare option xdmp:mapping "false";

declare variable $query := ();

declare function snip:clean-query($queries) {
  for $query in $queries
  return
  typeswitch ($query)
  case element(cts:collection-query)
    return ()
  case element(cts:and-query)
    return snip:copy-recurse($query)
  case element(cts:or-query)
    return snip:copy-recurse($query)
  case element(cts:near-query)
    return snip:copy-recurse($query)
  case element(cts:not-query)
    return snip:copy-recurse($query)
  default
    return $query
};

declare function snip:copy-recurse($query) {
  element { node-name($query) } {
    $query/namespace::*,
    $query/@*,
    snip:clean-query($query/node())
  }
};

declare function snip:find-all($nodes, $query) {
  for $node in $nodes
  return
    if ($node/*) then
      snip:find-all($node/*, $query)
    else if (cts:contains($node, $query)) then
      let $highlighted := cts:highlight($node, $query, element search:highlight { $cts:text })
			return
				if ($highlighted/search:highlight) then $highlighted else $node
    else ()
};

declare function snip:snippet(
  $result as node()?,
  $ctsquery as schema-element(cts:query),
  $options as element(search:transform-results)?
) as element(search:snippet) {
  let $_ :=
    if (empty($query)) then
      (: strip off stuff like collection-queries, as that might give false positives, and cache cleaned query for next results :)
      let $_ := xdmp:set($query, snip:clean-query($ctsquery)/cts:query(.))
      let $_ := xdmp:log($query)
      return $query
    else ()
  return
  if (exists(cts:and-query-queries($query))) then
    <search:snippet xmlns:search="http://marklogic.com/appservices/search">{
			let $max-matches := ($options/search:max-matches/xs:int(.), 2)[1]
			let $max-snippet-chars := ($options/search:max-snippet-chars/xs:int(.), 150)[1]

	      for $match in subsequence(snip:find-all($result, $query), 1, $max-matches)
				let $highlights :=
					if ($match/search:highlight) then
						$match/search:highlight
					else $match
				let $_ := xdmp:log($highlights)

					for $highlight in subsequence($highlights, 1, $max-matches)
					let $prev := $highlight/preceding-sibling::node()[1 to 3]
					let $next := $highlight/following-sibling::node()[1 to 3]
		      return
						<search:match path="{xdmp:path($match)}">{
							if ($prev) then
								let $prev := string-join($prev, "")
								return
									(".." || substring($prev, string-length($prev) - $max-snippet-chars))
							else (),

		          element search:highlight { $highlight/node() },

							if ($next) then
								let $next := string-join($next, "")
								return
									(substring($next, 1, $max-snippet-chars) || "..")
							else ()
		        }</search:match>
    }</search:snippet>
  else
    (: default snippeting for empty search :)
    search:snippet($result, $ctsquery, $options)
};
