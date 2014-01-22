xquery version "1.0-ml";

module namespace html = "http://marklogic.com/roxy/lib/patent-html";

declare option xdmp:mapping "false";

declare function html:walk-tree($x)
{
  for $y in $x/node()
  return html:transform($y)
};

declare function html:transform($x)
{
  typeswitch($x)
    case processing-instruction() return ()
    case element(drawings) return ()
    case element(p) return <p id="{ $x/@id }">{ html:walk-tree($x) }</p>
    case element(heading) return <h3>{ html:walk-tree($x) }</h3>
    case element(figref) return <span class="figref">{ html:walk-tree($x) }</span>
    case element(b) return <strong>{ html:walk-tree($x) }</strong>
    case element(claim-text) return
      if ($x/claim-text)
      then <div>{ html:walk-tree($x) }</div>
      else <p>{ html:walk-tree($x) }</p>
    case element(claim-ref) return <a class="claim-ref" href="{ $x/@idref }">{ html:walk-tree($x) }</a>
    case element() return
      if ($x/*)
      then html:walk-tree($x)
      else $x
    default return $x
};

declare function html:transform-html($x)
{
  <div class="patent-result">
    <h1>{ $x/us-bibliographic-data-grant/invention-title/fn:string() }</h1>
    <div class="abstract">{ html:walk-tree($x/abstract) }</div>
    <div class="classification">{
      for $class in $x/us-bibliographic-data-grant/classifications-ipcr/classification-ipcr
      let $str := fn:string-join($class/(section|class|subclass|main-group|subgroup), "")
      let $TODO := (: symbol-position|classification-value :) ()
      return
        <div class="ipc" data-version="{ $class/date/@date }">{ $str }</div>
    }</div>
    <div class="citations">
      <div class="patent-citations">{
        for $cite in $x/us-bibliographic-data-grant/us-references-cited/us-citation[patcit]
        let $doc := $cite/patcit/document-id
        let $str := $doc/country || " - " || $doc/doc-number || (" (" || $doc/name || ")")[$doc/name]
        return <div class="citation">{ $str }</div>
      }</div>
      <div class="non-patent-citations">{
        for $cite in $x/us-bibliographic-data-grant/us-references-cited/us-citation[nplcit]
        let $str := $cite/nplcit/othercit/fn:string()
        return <div class="citation">{ $str }</div>
      }</div>
    </div>
    <div class="description">{ html:walk-tree($x/description) }</div>
    <div class="claims">
      <h2>{ html:walk-tree($x/us-claim-statement) }</h2>
      {
        for $claim in $x/claims/claim
        return <div class="claim" id="{ $claim/@id }">{ html:walk-tree($claim) }</div>
      }
    </div>
  </div>
};
