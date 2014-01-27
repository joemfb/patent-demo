xquery version "1.0-ml";

module namespace appidentitytransform = "http://marklogic.com/rest-api/transform/appidentitytransform";

import module namespace extut = "http://marklogic.com/rest-api/lib/extensions-util" at "/MarkLogic/rest-api/lib/extensions-util.xqy";
import module namespace html = "http://marklogic.com/roxy/lib/patent-html" at "/application/custom/ext/patent-html-lib.xqy";
import module namespace cj = "http://marklogic.com/roxy/lib/classification-json" at "/application/custom/ext/classification-json-lib.xqy";
import module namespace pj = "http://marklogic.com/roxy/lib/patent-json" at "/application/custom/ext/patent-json-lib.xqy";

declare namespace xsl = "http://www.w3.org/1999/XSL/Transform";
declare namespace pt = "http://example.com/patent";
declare namespace class = "http://example.com/classification";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare private variable $transform := <xsl:stylesheet version="2.0" exclude-result-prefixes="xdmp xhtml" extension-element-prefixes="xdmp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/1999/xhtml" xmlns:xdmp="http://marklogic.com/xdmp" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:map="http://marklogic.com/xdmp/map" xmlns:search="http://marklogic.com/appservices/search">
  <xdmp:import-module namespace="http://marklogic.com/appservices/search" href="/MarkLogic/appservices/search/search.xqy"/>
  <xsl:param name="context" as="map:map"/>
  <xsl:param name="params" as="map:map"/>
  <xsl:variable name="mode" select="(map:get($params,&quot;mode&quot;),&quot;full&quot;)[1]"/>
  <xsl:variable name="docid" select="tokenize(map:get($params,&quot;docid&quot;),&quot;,&quot;)"/>
  <xsl:output method="xhtml" doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN" doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd" encoding="utf8" omit-xml-declaration="yes" indent="yes"/>
  <xsl:template match="/" as="item()*">
    <xsl:choose>
      <xsl:when test="xdmp:node-kind(node()) eq 'binary'">
        <xsl:sequence select="map:put($context,'output-type','*/*')"/>
        <xsl:sequence select="."/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="$mode eq 'info'">
            <xsl:apply-templates select="/" mode="info"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="/" mode="full"/>
          </xsl:otherwise>
        </xsl:choose>   
      </xsl:otherwise>
    </xsl:choose> 
  </xsl:template>
  <xsl:template match="/" mode="info" as="item()*">
    <div class="infowindow">
      <strong><xsl:value-of select="substring(.,1,30)" disable-output-escaping="no"/></strong><br clear="none"/>
      <p><xsl:copy-of select="search:snippet(.,search:parse(&quot; &quot;))" copy-namespaces="yes"/></p>
    </div>
  </xsl:template>
  <xsl:template match="/" mode="full" as="item()*">
    <html version="-//W3C//DTD XHTML 1.1//EN">
      <head>
        <title>Patent Demo</title>
        <meta http-equiv="Content-Type" content="text/html; charset=utf8"/>
        <meta http-equiv="X-UA-Compatible" content="IE=9"/>
        <link type="text/css" rel="stylesheet" href="/application/css/reset.css" media="screen, print"/>
        <link type="text/css" rel="stylesheet" href="/application/css/style.css" media="screen, print"/>
        <link type="text/css" rel="stylesheet" href="/application/skin.css" media="screen, print"/>
        <link type="text/css" rel="stylesheet" href="/application/app.css" media="screen, print"/>
        <link type="text/css" rel="stylesheet" href="/application/lib/external/jqueryui/jquery-ui-1.10.4.custom.css" media="screen, print"/>
        <link type="text/css" rel="stylesheet" href="/application/custom/app.css" media="screen, print"/>
        <meta name="user" content="{xdmp:get-current-user()}"/>
      </head>
      <body>
        <xsl:copy-of select="map:get($params,'mode')" copy-namespaces="yes"/>
        <div id="container"> 	
          <div id="header">
            <h1 id="logo">
               Patent Demo 
            </h1>
            <div class="user">Welcome, <span id="username"><xsl:value-of select="xdmp:get-current-user()" disable-output-escaping="no"/></span></div>
          </div>
          <div id="content" class="subpage">
            <div id="content-area-container">
              <div id="content-area">
                <xsl:copy-of select="child::node()"/>
              </div>
            </div>
          </div>		
          <div id="footer" class="footer">
    	    	<p>
    	    		<span class="copyright">© 2012-2013, MarkLogic Corporation, All Rights Reserved.</span>
    	    		<a href="/content/help">Patent Demo Help</a> <span class="pipe"></span> 
    	    		<a href="/content/contact">Contact MarkLogic Corporation</a> <span class="pipe"></span> 
    	    		<a href="/content/terms">Terms of Use</a>
    	    	</p>
          </div>		
        </div>
        <div id="debug"></div>
        <script src="/application/lib/external/jquery-1.7.1.min.js" type="text/javascript" xml:space="preserve"></script>
        <script src="/application/lib/external/jquery-ui-1.10.4.custom.js" type="text/javascript" xml:space="preserve"></script>
        <script src="/application/lib/external/trunk8.js" type="text/javascript" xml:space="preserve"></script>
        <script src="/application/skin.js" type="text/javascript" xml:space="preserve"></script>
        <script src="/application/custom/app.js?4925867444361487418" type="text/javascript" xml:space="preserve"></script>
      </body>
    </html>
  </xsl:template>
<!--
  <xsl:include href="/application/app-content.xsl"/>
  <xsl:include href="/application/custom/content.xsl"/>
-->
</xsl:stylesheet>;

declare function appidentitytransform:transform(
    $context as map:map,
    $params  as map:map,
    $content as document-node()  
) as document-node()?
{
    if ($content/pt:*)
    then
      if (xdmp:get-request-field("format") eq "json")
      then document { pj:to-json($content/*) }
      else extut:execute-transform($transform, $context, $params, document { html:transform-patent($content/*) })
    else
      if ($content/class:ipc-entry)
      then
        if (xdmp:get-request-field("format") eq "json")
        then document { cj:to-json($content/*) }
        else
          if (xdmp:get-request-field("format") eq "xml")
          then $content
          else html:serialize(html:transform($content/*))
      else $content
};
