xquery version "1.0-ml";

module namespace enhance = "http://marklogic.com/roxy/lib/patent-enhance";

import module namespace patent = "http://marklogic.com/roxy/models/patent" at "/application/custom/ext/patent-lib.xqy";

declare namespace pt = "http://example.com/patent";

declare option xdmp:mapping "false";

declare function enhance:transform($content as map:map, $context as map:map) as map:map*
{
  let $doc := map:get($content, "value")/pt:us-patent-grant
  return
    if ($doc)
    then
    (
      map:put($content, "value",
        document {enhance:transform($doc)}),
      $content
    )
    else $content
};

declare function enhance:walk-tree($x)
{
  for $y in $x/node()
  return enhance:transform($y)
};

declare function enhance:transform($x)
{
  typeswitch($x)
    case element(pt:date) return
      element { fn:node-name($x) } {
        $x/@*,
        attribute date { xdmp:parse-yymmdd("yyyyMMDD", $x) ! xs:date(.) },
        $x/fn:data(.)
      }
    case element (pt:classification-ipcr) return
      element { fn:node-name($x) } {
        $x/@*,
        attribute code { patent:ipc-string($x) },
        enhance:walk-tree($x)
      }
    case element() return
      element { fn:node-name($x) } {
        $x/@*,
        enhance:walk-tree($x)
      }
    default return $x
};
