xquery version "1.0-ml";

module namespace process = "http://marklogic.com/roxy/lib/classification-process";

declare namespace pt = "http://example.com/patent";
declare namespace class = "http://example.com/classification";

declare option xdmp:mapping "false";

declare variable $process:base-uri := "/classifications/ipc/split/ipcr_scheme_20140101.";

declare function process:save($uri, $data)
{
  xdmp:document-insert($uri, $data),
  $uri
};

declare function process:transform($x as element(class:ipcEntry))
{
  element class:ipc-entry {
    attribute xml:lang { fn:lower-case($x/@lang) },
    element class:kind { $x/@kind/fn:string() },
    element class:symbol { $x/@symbol/fn:string() },
    (: TODO: date-parse :)
    element class:edition { $x/@edition/fn:string() },
    element class:entry-type { $x/@entryType/fn:string() },
    (: ignoring class:index and class:note :)
    $x/class:textBody,
    element class:ipc-entries { process:process($x/class:ipcEntry) }
  }
};

declare function process:process($y as element(class:ipcEntry)*)
{
  for $x in $y
  return
    if (fn:not($x/@kind eq "n"))
    then
      element class:ipc-entry-ref {
        element class:ref-code { $x/@symbol/fn:string() },
        element class:uri {
          let $uri := $process:base-uri || $x/@symbol || "." || $x/@kind || "." || $x/@entryType || ".xml"
          return process:save($uri, process:transform($x))
        }
      }
    else ()
};

declare function process:process()
{
  fn:exists(process:process(/class:revisionPeriods//class:en/class:staticIpc/class:ipcEntry))
};

(:
Data Structure Notes:

fn:string-join(fn:distinct-values(//class:en//class:ipcEntry/@kind), " ")
=> "s t c u i m 1 2 g 3 4 n 5 6 7 8 9 A"

TODO
"s" is root
"t" is +1
...
:)
