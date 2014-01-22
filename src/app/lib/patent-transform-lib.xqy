xquery version "1.0-ml";

module namespace pat = "http://marklogic.com/roxy/lib/patent-transform";

import module namespace patent = "http://marklogic.com/roxy/models/patent" at "/app/models/patent.xqy";

declare option xdmp:mapping "false";

declare function pat:transform($content as map:map, $context as map:map) as map:map*
{
  let $doc := map:get($content, "value")/us-patent-grant
  return
    if ($doc)
    then
    (
      map:put($content, "value",
        document {pat:transform($doc)}),
      $content
    )
    else $content
};

declare function pat:walk-tree($x)
{
  for $y in $x/node()
  return pat:transform($y)
};

declare function pat:transform($x)
{
  typeswitch($x)
    case element(date) return
      element date {
        $x/@*,
        attribute date { xdmp:parse-yymmdd("yyyyMMDD", $x) ! xs:date(.) },
        $x/fn:data(.)
      }
    case element (classification-ipcr) return
      element classification-ipcr {
        $x/@*,
        attribute code { patent:ipc-string($x) },
        pat:walk-tree($x)
      }
    case element() return
      element { fn:node-name($x) } {
        $x/@*,
        pat:walk-tree($x)
      }
    default return $x
};
