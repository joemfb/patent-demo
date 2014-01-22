xquery version "1.0-ml";

module namespace u = "http://marklogic.com/roxy/lib/util";

declare option xdmp:mapping "false";

declare function u:string-pad($str as xs:string?, $len as xs:integer) as xs:string
{
  fn:string-join((for $i in 1 to $len return $str), "")
};
