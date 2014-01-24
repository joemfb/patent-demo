xquery version "1.0-ml";

module namespace m = "http://marklogic.com/roxy/models/patent";

import module namespace u = "http://marklogic.com/roxy/lib/util" at "/application/custom/ext/util.xqy";

declare namespace pt = "http://example.com/patent";

declare option xdmp:mapping "false";

declare function m:ipc-string($x as element(pt:classification-ipcr)) as xs:string
{
  let $class := fn:string-join($x/(pt:section|pt:class|pt:subclass), "")
  let $group := u:string-pad("0", 4 - fn:string-length($x/pt:main-group)) ||  $x/pt:main-group
  let $subgroup :=  $x/pt:subgroup || u:string-pad("0", 6 - fn:string-length($x/pt:subgroup))
  return fn:string-join(($class, $group, $subgroup), "")
};
