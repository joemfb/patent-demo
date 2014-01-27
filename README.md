**SETUP**

Update credentials / port numbes in `deploy/build.properties`, then:

    ml local bootstrap
    ml local deploy modules
    mlcp.sh -options_file mlcp.patent.properties
    mlcp.sh -options_file mlcp.ipc-class.properties

Then, unfortunately, in QC, select `patent-demo-content` and run:

    import module namespace process = "http://marklogic.com/roxy/lib/classification-process"
      at "/application/custom/ext/classification-process-lib.xqy";
    process:process()

Note the commented-out transformation in `mlcp.ipc-class.properties`
(see known issues for details)

**FUNCTIONALITY**

**Landing Page**

Typical assessment builder search app. The only enhancements to this page are the tooltips
for the classification facet/chiclet, but they only display on page load (see known issues).

**Patent Document View**

This is a customized interface. The patent document is transformed into HTML on the server,
and then enhanced with a variety of related JSON data retrieved via the REST API.
Referenced classifications are retrieved, and can be further explored in a pop-up window.
Patents related to those classifications are also linked. Users can request a licence
for the patent, or suggest prior art that my invalidate the patent.
Cited patents are linked (although most won't exist, see known issues).

**KNOWN ISSUES**

**Classification Facet Tooltips**

The classification description tooltips only display on page load. I spent several hours
experiment with MutationObservers and overriding jQuery functions to emit custom events,
but was unable to reliably display the tooltips as a user interacts with them.

**MLCP Transformation Errors**

I implemented an XQuery module for transforming the classification XML when uploaded with MLCP,
but, for reasons I can't determine, that transformation errors out: 'missing socket'.
I read through the MLCP source, but the actual error is from com.marklogic.mapreduce.ContentWriter,
which is in a separate project. The configuration works fine without the transformation., 
so something else is causing the socket to disappear. I created a simple test case to
split documents via MLCP, and that worked just fine.

**Patent Citations Dead Links**

The majority of patent citation links with simply display "no results found".
This is because I've only included a small quantity of patent documents.
Years worth of patents would obviously be many GB of XML ...

**Patent Images Missing**

Patent images are not included in the source data from http://patents.reedtech.com/pgrbft.php

**NOTES**

The patent XML is published as a ZIP archive of a single "XML" file, which is actually
a concatenation of thousand's of XML files. I split that into files using `awk`:

    awk '/^<\?xml/{close(x);x="ipg140107."++i".xml";next}{print > x;}' ../ipg140107.xml

**RESOURCE LINKS**

Classifications info:
http://www.uspto.gov/patents/resources/classification/

IPC Classifications:
http://www.wipo.int/classifications/ipc/en/ITsupport/Version20140101/index.html
http://www.wipo.int/ipc/itos4ipc/ITSupport_and_download_area/20140101/definitions_viewer/en/en_20140101_definitions_viewer.htm

IPC XML schema:
http://www.wipo.int/ipc/itos4ipc/ITSupport_and_download_area/20140101/MasterFiles/
IPC Schema docs:
http://www.wipo.int/export/sites/www/classifications/ipc/en/guide/guide_ipc.pdf
http://www.wipo.int/classifications/ipc/en/faq/#G17

Patent XML:
http://patents.reedtech.com/pgrbft.php

Patent XML Schema Docs:
http://www.uspto.gov/products/PatentGrantXMLv42-Documentation.pdf

Miscellaneous Resources

CPC:
http://www.cooperativepatentclassification.org/cpcSchemeAndDefinitions/Bulk.html
http://intellogist.wordpress.com/2012/07/12/ready-or-not-the-cooperative-patent-classification-has-arrived/

US:
http://patents.reedtech.com/classdata.php
