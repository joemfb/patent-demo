xquery version "1.0-ml";

module namespace enhance = "http://marklogic.com/roxy/lib/ipc-classification-enhance";

declare namespace pt = "http://example.com/patent";
declare namespace class = "http://example.com/classification";

declare option xdmp:mapping "false";

declare function enhance:transform($content as map:map, $context as map:map) as map:map*
{
  let $doc := map:get($content, "value")/class:revisionPeriods
  return
  (
    xdmp:log("hello: " || fn:exists($doc), "error"),
    if ($doc)
    then
      for $entry in $doc//class:en/class:staticIpc/class:ipcEntry
      let $map := map:map()
      let $uri := fn:replace(map:get($content, "uri"), "^(.*)(\.xml)$", "$1." || $entry/@symbol || "$2")
      return
      (
        map:put($map, "uri", $uri),
        map:put($map, "collections", map:get($content, "collections")),
        map:put($map, "permissions", map:get($content, "permissions")),
        map:put($map, "quality", map:get($content, "quality")),
        map:put($map, "value", document { enhance:transform($entry) }),
        xdmp:log($uri, "error"),
        $map
      )
    else $content
  )
};

declare function enhance:walk-tree($x)
{
  for $y in $x/node()
  return enhance:transform($y)
};

declare function enhance:transform($x)
{
  typeswitch($x)
    case element() return $x
    default return $x
};
