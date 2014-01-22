xquery version "1.0-ml";

module namespace m = "http://marklogic.com/roxy/models/patent";

import module namespace u = "http://marklogic.com/roxy/lib/util" at "/app/lib/util.xqy";

declare option xdmp:mapping "false";

declare function m:ipc-string($x as element(classification-ipcr)) as xs:string
{
  let $class := fn:string-join($x/(section|class|subclass), "")
  let $group := u:string-pad("0", 4 - fn:string-length($x/main-group)) ||  $x/main-group
  let $subgroup :=  $x/subgroup || u:string-pad("0", 6 - fn:string-length($x/subgroup))
  return fn:string-join(($class, $group, $subgroup), "")
};
