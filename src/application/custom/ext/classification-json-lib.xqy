xquery version "1.0-ml";

module namespace cj = "http://marklogic.com/roxy/lib/classification-json";

import module namespace html = "http://marklogic.com/roxy/lib/patent-html" at "/application/custom/ext/patent-html-lib.xqy";
import module namespace json="http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";

declare namespace jsonb = "http://marklogic.com/xdmp/json/basic";
declare namespace pt = "http://example.com/patent";
declare namespace class = "http://example.com/classification";

declare option xdmp:mapping "false";

declare function cj:transform($y)
{
  for $x in $y
  return
    typeswitch($x)
      case element(class:ipc-entries) return
        element jsonb:ipc-entries {
          attribute type { "array" },
          cj:transform($x/class:ipc-entry-ref)
        }
      case element(class:ipc-entry-ref) return
        element jsonb:ipc-entry-ref {
          attribute type {"object"},
          cj:transform($x/*)
        }
      case element(class:textBody) return
        element jsonb:text-body {
          attribute type { "string" },
          xdmp:quote(
            html:serialize(
              html:transform($x)))
        }
      case element() return
        if ($x[fn:not(*)])
        then
          element { xs:QName("jsonb:" || fn:local-name($x)) } {
            attribute type { "string" },
            fn:data($x)
          }
        else xdmp:quote($x)
      default return $x
};

declare function cj:to-json($x)
{
  json:transform-to-json(
    element jsonb:json {
      attribute type { "object" },
      cj:transform($x/*)
    }
  )
};
