xquery version "1.0-ml";

module namespace html = "http://marklogic.com/roxy/lib/patent-html";

declare namespace pt = "http://example.com/patent";
declare namespace class = "http://example.com/classification";
declare namespace xhtml = "http://www.w3.org/1999/xhtml";

declare option xdmp:mapping "false";

declare function html:serialize($x)
{
  let $stylesheet :=
    <xsl:stylesheet version="2.0" exclude-result-prefixes="xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/1999/xhtml" xmlns:xhtml="http://www.w3.org/1999/xhtml">
      <xsl:output method="xhtml" encoding="utf8" omit-xml-declaration="yes" indent="yes"/>
      <xsl:template match="/">
        <div>
          <xsl:copy-of select="child::node()"/>
        </div>
      </xsl:template>
    </xsl:stylesheet>
  return xdmp:xslt-eval($stylesheet, document { $x })
};

declare function html:walk-tree($x)
{
  html:transform($x/node())
};

declare function html:transform($y)
{
  for $x in $y
  return
    typeswitch($x)
      case processing-instruction()        return ()
      case element(pt:drawings)            return ()
      case element(pt:residence)           return ()
      case element(pt:p)                   return <xhtml:p id="{ $x/@id }">{ html:walk-tree($x) }</xhtml:p>
      case element(pt:heading)             return <xhtml:h3>{ html:walk-tree($x) }</xhtml:h3>
      case element(pt:figref)              return <xhtml:span class="figref">{ html:walk-tree($x) }</xhtml:span>
      case element(pt:b)                   return <xhtml:strong>{ html:walk-tree($x) }</xhtml:strong>
      case element(pt:us-citation)         return html:citation($x)
      case element(pt:addressbook)         return html:addressbook($x)
      case element(pt:claim)               return html:claim($x)
      case element(pt:claim-text)          return html:claim-text($x)
      case element(pt:claim-ref)           return <xhtml:a class="claim-ref" href="{ $x/@idref }">{ html:walk-tree($x) }</xhtml:a>
      case element(pt:classification-ipcr) return html:ipc-classification($x)
      case element(class:ipc-entry)        return html:ipc-entry($x)
      case element(class:ipc-entry-ref)    return html:ipc-entry-ref($x)
      case element(class:titlePart)        return html:title-part($x)
      case element(class:text)             return <xhtml:span>{ html:walk-tree($x) }</xhtml:span>
      case element(class:entryReference)   return <xhtml:li>{ html:walk-tree($x) }</xhtml:li>
      case element(class:sref)             return html:ipc-entry-search($x)
      case element() return
        if ($x/*)
        then html:walk-tree($x)
        else $x
      default return $x
};

declare function html:citation($x)
{
  if ($x[pt:patcit])
  then
    let $doc := $x/pt:patcit/pt:document-id
    let $country := $doc/pt:country/fn:string()
    return
      <div class="citation" xmlns="http://www.w3.org/1999/xhtml">
        <span class="country">{ $country }</span> - 
        {
          if ($country eq "US")
          then <a class="patent-number" href="#">{ $doc/pt:doc-number/fn:string() }</a>
          else <span>{ $doc/pt:doc-number/fn:string() }</span>
          ,
          if ($doc/pt:name)
          then ("&nbsp;(", <span class="name">{$doc/pt:name/fn:string() }</span>, ")")
          else ()
        }
      </div>
  else
    if ($x[pt:nplcit])
    then <xhtml:div class="citation">{ $x/pt:nplcit/pt:othercit/fn:string() }</xhtml:div>
    else ()
};

declare function html:claim($x)
{
  <div class="claim" id="{ $x/@id }">{ html:walk-tree($x) }</div>
};

declare function html:claim-text($x)
{
  if ($x/pt:claim-text)
  then <xhtml:div>{ html:walk-tree($x) }</xhtml:div>
  else <xhtml:p>{ html:walk-tree($x) }</xhtml:p>
};

declare function html:title-part($x)
{
  <xhtml:div class="claim-title">
  {
    html:transform($x/class:text),
    <xhtml:ul class="entryReferences">{ html:transform($x/class:entryReference) }</xhtml:ul>
  }
  </xhtml:div>
};

declare function html:ipc-classification($x)
{
  <xhtml:div class="ipc" data-version="{ $x/pt:date/@date }" data-code="{ $x/@code/fn:string() }">
    <xhtml:strong>{ $x/@code/fn:string() }</xhtml:strong>
  </xhtml:div>
};

declare function html:ipc-entry($x)
{
  <xhtml:div class="ipc-entry">
  {
    html:transform($x/class:textBody),
    if ($x/class:ipc-entries/*)
    then
      <xhtml:ul class="ipc-children">
        <xhtml:h3>Sub-Classifications</xhtml:h3>
        { html:transform($x/class:ipc-entries/*) }
      </xhtml:ul>
    else ()
  }
  </xhtml:div>
};

declare function html:ipc-entry-ref($x)
{
  (: TODO: confirm link :)
  let $uri := "documents?uri=" || $x/class:uri
  let $code := $x/class:ref-code/fn:string()
  return
    <xhtml:li> 
      <xhtml:a class="ipc-entry-ref" href="{ $uri }" data-code="{ $code }">{ $code }</xhtml:a>
    </xhtml:li>
};

declare function html:ipc-entry-search($x)
{
  <xhtml:a class="ipc-entry-search" href="#" data-code="{ $x/@ref }">{ $x/@ref/fn:string() }</xhtml:a>
};

declare function html:addressbook($x)
{
  let $name :=
    if ($x/pt:orgname)
    then $x/pt:orgname/fn:string()
    else $x/pt:first-name || " " || $x/pt:last-name
  return
    <xhtml:li>
      <xhtml:span>{ $name }</xhtml:span>
      { "&nbsp;" }
      <xhtml:span>{ "(" || $x/pt:address/pt:city || ", " || $x/pt:address/pt:country || ")" }</xhtml:span>
    </xhtml:li>
};

declare function html:dates($x)
{
  <xhtml:h5 class="dates">
    <xhtml:span>Applied <xhtml:span class="date">{ $x//pt:application-reference/pt:document-id/pt:date/@date ! xs:dateTime(xs:date(.)) }</xhtml:span></xhtml:span>
    { ",&nbsp;" }
    <xhtml:span>Granted <xhtml:span class="date">{ $x//pt:publication-reference/pt:document-id/pt:date/@date ! xs:dateTime(xs:date(.)) }</xhtml:span></xhtml:span>
  </xhtml:h5>
};

declare function html:additional-info($x)
{
  <div class="additional-info" xmlns="http://www.w3.org/1999/xhtml">
    <div class="inventors">
      <h4>Inventors:</h4>
      <ul>{ html:transform($x//pt:inventors/pt:inventor) }</ul>
    </div>
    <div class="applicants">
      <h4>Applicants:</h4>
      <ul>{ html:transform($x//pt:us-applicants/pt:us-applicant) }</ul>
    </div>
    <div class="assignee">
      <h4>Assignees:</h4>
      <ul>{ html:transform($x//pt:assignees/pt:assignee) }</ul>
    </div>
  </div>
};

declare function html:licensing()
{
  <div class="licensing" xmlns="http://www.w3.org/1999/xhtml">
    <h3>Licensing Requests</h3>
    <table class="licensing-entries ui-widget ui-widget-content">
      <thead>
        <tr class="ui-widget-header ">
          <th class="name ui-state-default">Name</th>
          <th class="requested ui-state-default">Requested</th>
          <th class="company ui-state-default">Company</th>
          <th class="description ui-state-default">Description</th>
          <th class="comments ui-state-default">Comments</th>
        </tr>
      </thead>
    </table>
    <button class="request-licensing">request a license</button>
    <form class="licensing-form">
      <fieldset>
        <label for="name">Name: </label>
        <input type="text" name="name" id="name" class="text ui-widget-content ui-corner-all" xml:space="preserve"></input>
        <label for="company">Company: </label>
        <input type="text" name="company" id="company" class="text ui-widget-content ui-corner-all" xml:space="preserve"></input>
        <label for="email">Email: </label>
        <input type="text" name="email" id="email" class="text ui-widget-content ui-corner-all" xml:space="preserve"></input>
        <label for="phone">Phone Number: </label>
        <input type="text" name="phone" id="phone" class="text ui-widget-content ui-corner-all" xml:space="preserve"></input>
        <label for="description">Product Description:</label>
        <textarea name="description" cols="45" rows="6" id="comments" placeholder="Describe your intended product ..." class="ui-widget ui-state-default ui-corner-all" xml:space="preserve"></textarea>
        <label for="comments">Comments:</label>
        <textarea name="comments" cols="45" rows="6" id="comments" placeholder="Additional comments ..." class="ui-widget ui-state-default ui-corner-all" xml:space="preserve"></textarea>
        <input type="hidden" name="uri" id="uri" value="" xml:space="preserve"></input>
        <input type="hidden" name="created" id="created" value="" xml:space="preserve"></input>
      </fieldset>
    </form>
  </div>
};

declare function html:prior-art()
{
  <div class="prior-art" xmlns="http://www.w3.org/1999/xhtml">
    <h3>Suggested Prior Art</h3>
    <table class="prior-art-entries ui-widget ui-widget-content">
      <thead>
        <tr class="ui-widget-header ">
          <th class="name ui-state-default">Name</th>
          <th class="requested ui-state-default">Requested</th>
          <th class="external-link ui-state-default">External Link</th>
          <th class="comments ui-state-default">Comments</th>
        </tr>
      </thead>
    </table>
    <button class="add-prior-art">add prior art</button>
    <form class="prior-art-form">
      <fieldset>
        <label for="name">Name: </label>
        <input type="text" name="name" id="name" class="text ui-widget-content ui-corner-all" xml:space="preserve"></input>
        <label for="email">Email: </label>
        <input type="text" name="email" id="email" class="text ui-widget-content ui-corner-all" xml:space="preserve"></input>
        <label for="external-link">External Link: </label>
        <input type="text" name="external-link" id="external-link" class="text ui-widget-content ui-corner-all" xml:space="preserve"></input>
        <label for="comments">Comments:</label>
        <textarea name="comments" cols="35" rows="6" id="comments" placeholder="Add your comments ..." class="ui-widget ui-state-default ui-corner-all" xml:space="preserve"></textarea>
        <input type="hidden" name="uri" id="uri" xml:space="preserve"></input>
        <input type="hidden" name="created" id="created" xml:space="preserve"></input>
      </fieldset>
    </form>
  </div>
};

declare function html:transform-patent($x)
{
  <div class="patent-result" xmlns="http://www.w3.org/1999/xhtml">
    <h2 class="patent-title">{ html:transform($x//pt:invention-title) }</h2>
    <div class="patent-contents">
      { html:dates($x) }
      { (: TODO: why does normal indentation create extra space here? :) }
      <div class="abstract"><h3>Abstract</h3>{ html:transform($x/pt:abstract) }</div>
      <div class="classification">
        <h3>Classifications</h3>
        { html:transform($x//pt:classification-ipcr) }
      </div>
      {
        html:additional-info($x),
        html:licensing(),
        html:prior-art()
      }
      <div class="description">
        <h3 class="description-title">Description</h3>
        <div class="description-contents">{ html:transform($x/pt:description) }</div>
      </div>
      <div class="claims">
        <h3 class="claims-title">{ html:transform($x/pt:us-claim-statement) }</h3>
        <div class="claims-contents">{ html:transform($x/pt:claims/pt:claim) }</div>
      </div>
      <div class="patent-citations">
        <h3>Patent Citations</h3>
        <div class="citations-contents">{ html:transform($x//pt:us-citation[pt:patcit]) }</div>
      </div>
      <div class="non-patent-citations">
        <h3>Non-Patent Citations:</h3>
        <div class="citations-contents">{ html:transform($x//pt:us-citation[pt:nplcit]) }</div>
      </div>
    </div>
  </div>
};
