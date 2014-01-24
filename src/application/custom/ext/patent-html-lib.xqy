xquery version "1.0-ml";

module namespace html = "http://marklogic.com/roxy/lib/patent-html";

declare namespace pt = "http://example.com/patent";
declare namespace xhtml = "http://www.w3.org/1999/xhtml";

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
    case element(pt:drawings) return ()
    case element(pt:p) return <xhtml:p id="{ $x/@id }">{ html:walk-tree($x) }</xhtml:p>
    case element(pt:heading) return <xhtml:h3>{ html:walk-tree($x) }</xhtml:h3>
    case element(pt:figref) return <xhtml:span class="figref">{ html:walk-tree($x) }</xhtml:span>
    case element(pt:b) return <xhtml:strong>{ html:walk-tree($x) }</xhtml:strong>
    case element(pt:claim-text) return
      if ($x/pt:claim-text)
      then <xhtml:div>{ html:walk-tree($x) }</xhtml:div>
      else <xhtml:p>{ html:walk-tree($x) }</xhtml:p>
    case element(pt:claim-ref) return <xhtml:a class="claim-ref" href="{ $x/@idref }">{ html:walk-tree($x) }</xhtml:a>
    case element() return
      if ($x/*)
      then html:walk-tree($x)
      else $x
    default return $x
};

declare function html:transform-html($x)
{
  <div class="patent-result" xmlns="http://www.w3.org/1999/xhtml">
    <h2 class="patent-title">{ $x/pt:us-bibliographic-data-grant/pt:invention-title/fn:string() }</h2>
    <div class="patent-contents">
      <div class="abstract">
        <label>Abstract:</label>
      { html:walk-tree($x/pt:abstract) }
      </div>
      <div class="classification">
        <label>Classification:</label>
      {
        for $class in $x/pt:us-bibliographic-data-grant/pt:classifications-ipcr/pt:classification-ipcr
        let $str := fn:string-join($class/(pt:section|pt:class|pt:subclass|pt:main-group|pt:subgroup), "")
        let $TODO := (: symbol-position|classification-value :) ()
        return
          <div class="ipc" data-version="{ $class/pt:date/@date }">{ $str }</div>
      }</div>
      <div class="patent-citations">
        <label>Patent Citations:</label>
      {
        for $cite in $x/pt:us-bibliographic-data-grant/pt:us-references-cited/pt:us-citation[pt:patcit]
        let $doc := $cite/pt:patcit/pt:document-id
        let $country := $doc/pt:country/fn:string()
        return
          <div class="citation">
            <span class="country">{ $country }</span> - 
            {
              if ($country eq "US")
              then <a class="patent-number" href="#">{ $doc/pt:doc-number/fn:string() }</a>
              else <span>{ $doc/pt:doc-number/fn:string() }</span>
            }
            {
              if ($doc/pt:name)
              then ("&nbsp;(", <span class="name">{$doc/pt:name/fn:string() }</span>, ")")
              else ()
            }
          </div>
      }</div>
      <div class="licensing">
        <h2>Licensing Requests</h2>
        <button class="request-licensing">request a license</button>
      </div>
      <div class="prior-art">
        <h2>Suggested Prior Art</h2>
        <button class="add-prior-art">add prior art</button>
      </div>
      <div class="additional-info">
        <h2>Additional Information</h2>
        <div class="non-patent-citations">
          <label>Non-Patent Citations:</label>
        {
          for $cite in $x/pt:us-bibliographic-data-grant/pt:us-references-cited/pt:us-citation[pt:nplcit]
          let $str := $cite/pt:nplcit/pt:othercit/fn:string()
          return <div class="citation">{ $str }</div>
        }</div>
      </div>
      <div class="description">
        <h2 class="description-title">Description:</h2>
        <div class="description-contents">{ html:walk-tree($x/pt:description) }</div>
      </div>
      <div class="claims">
        <h2 class="claims-title">{ html:walk-tree($x/pt:us-claim-statement) }</h2>
        <div class="claims-contents">
        {
          for $claim in $x/pt:claims/pt:claim
          return <div class="claim" id="{ $claim/@id }">{ html:walk-tree($claim) }</div>
        }
        </div>
      </div>
    </div>
    <form class="licensing-form">
      <fieldset>
        <label for="name">Name: </label>
        <input type="text" name="name" id="name" class="text ui-widget-content ui-corner-all" xml:space="preserve"></input>
        <label for="email">Email: </label>
        <input type="text" name="email" id="email" class="text ui-widget-content ui-corner-all" xml:space="preserve"></input>
        <label for="comments">Comments:</label>
        <textarea name="comments" cols="35" rows="6" id="comments" placeholder="Add your comments ..." class="ui-widget ui-state-default ui-corner-all" xml:space="preserve"></textarea>
      </fieldset>
    </form>
    <form class="prior-art-form">
      <fieldset>
        <label for="name">Name: </label>
        <input type="text" name="name" id="name" class="text ui-widget-content ui-corner-all" xml:space="preserve"></input>
        <label for="email">Email: </label>
        <input type="text" name="email" id="email" class="text ui-widget-content ui-corner-all" xml:space="preserve"></input>
        <label for="comments">Comments:</label>
        <textarea name="comments" cols="35" rows="6" id="comments" placeholder="Add your comments ..." class="ui-widget ui-state-default ui-corner-all" xml:space="preserve"></textarea>
      </fieldset>
    </form>
  </div>
};
