xquery version "1.0-ml";

module namespace pj = "http://marklogic.com/roxy/lib/patent-json";

import module namespace html = "http://marklogic.com/roxy/lib/patent-html" at "/application/custom/ext/patent-html-lib.xqy";
import module namespace json="http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";

declare namespace jsonb = "http://marklogic.com/xdmp/json/basic";
declare namespace pt = "http://example.com/patent";
declare namespace class = "http://example.com/classification";

declare option xdmp:mapping "false";

declare function pj:transform($y)
{
  for $x in $y
  return
    typeswitch($x)
      case element(pt:publication-reference) return
        element jsonb:doc-number {
          attribute type { "string" },
          $x/pt:document-id/pt:doc-number/fn:string()
        }
      case element(pt:application-reference) return
        element jsonb:type {
          attribute type { "string" },
          $x/@appl-type/fn:string()
        }
      case element(pt:invention-title) return
        element jsonb:title {
          attribute type { "string" },
          $x/fn:string()
        }
      case element() return pj:transform($x/*)
      default return $x
};

declare function pj:to-json($x)
{
  json:transform-to-json(
    element jsonb:json {
      attribute type { "object" },
      pj:transform($x/*)
    }
  )
};
