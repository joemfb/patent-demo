xquery version "1.0-ml";

module namespace enhance = "http://marklogic.com/roxy/lib/patent-enhance";

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

declare function enhance:string-pad($str as xs:string?, $len as xs:integer) as xs:string
{
  fn:string-join((for $i in 1 to $len return $str), "")
};

declare function enhance:ipc-string($x as element(pt:classification-ipcr)) as xs:string
{
  let $class := fn:string-join($x/(pt:section|pt:class|pt:subclass), "")
  let $group := enhance:string-pad("0", 4 - fn:string-length($x/pt:main-group)) ||  $x/pt:main-group
  let $subgroup :=  $x/pt:subgroup || enhance:string-pad("0", 6 - fn:string-length($x/pt:subgroup))
  return fn:string-join(($class, $group, $subgroup), "")
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
        attribute code { enhance:ipc-string($x) },
        enhance:walk-tree($x)
      }
    case element() return
      element { fn:node-name($x) } {
        $x/@*,
        enhance:walk-tree($x)
      }
    default return $x
};
