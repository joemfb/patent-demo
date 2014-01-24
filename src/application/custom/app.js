/* Add any custom scripting for your built app here.
 * This file will survive redeployment.
 */

var urlParams = function() {
      //from https://stackoverflow.com/questions/901115/how-can-i-get-query-string-values-in-javascript/2880929#2880929
      var urlParams = {},
          match,
          pl     = /\+/g,  // Regex for replacing addition symbol with a space
          search = /([^&=]+)=?([^&]*)/g,
          decode = function (s) { return decodeURIComponent(s.replace(pl, " ")); },
          query  = window.location.search.substring(1);

      while (match = search.exec(query)) {
        urlParams[decode(match[1])] = decode(match[2])
      }
      return urlParams
    },

    /*
     * Find a Patent Document by it's publication number
     */
    findByPatentNum = function(patentNum, target, callback) {
      var searchUri = 'keyvalue?element=doc-number&value=' + patentNum+ '&format=json'
      
      $.get( searchUri, function( data ) {
        callback(data, target)
      })
    },

    /*
     * Navigate to a patent document by it's publication number
     */
    navigateToResult = function(data, target) {
      var uri,
          message,
          condition,
          result

      //TODO: check that isn't not the same doc
      uri = urlParams()["uri"]
      result = data.results[0]

      condition = result != null && result.uri !== uri
      condition = condition && /publication-reference/.test(result.matches[0].path)

      if ( condition ) {
        target.get(0).href = 'documents?uri=' + encodeURIComponent(result.uri)
      } else {
        message = $('<span class="message">&nbsp;&nbsp;no results found.</span>')
        target.parent().append(message)
        message.delay(750).fadeOut()
      }
    },

    /*
     * Prepare a json document from user input
     */
    prepareDoc = function(data, type) {
      data.uri = urlParams()["uri"]
      data.type = type
      data.username = $('#username').text()
      return data
    },

    /*
     *  save a new json document to ML
     */
    saveDoc = function(data, callback) {
      $.ajax({
        type: 'POST',
        url: 'documents?extension=json&directory=/user-content/' + encodeURIComponent(data.type) + '/',
        data: JSON.stringify(data),
        contentType: 'application/json',
        dataType: 'json'
      }).success(function(data, status, jqXHR) {
        callback(data)
      })
    },

    /*
     * Update an existing json doc in ML
     */
    updateDoc = function(data, uri, callback) {
      $.ajax({
        type: 'PUT',
        url: 'documents?uri=' + encodeURIComponent(uri),
        data: JSON.stringify(data),
        contentType: 'application/json',
        dataType: 'json'
      }).success(function(data, status, jqXHR) {
        callback(data)
      })
    },

    /*
     * Convert the output of jQuery.serializeArray() to an object with named properties
     */
    processFormData = function(formData) {
      var data = {}

      for (var i = 0; i < formData.length; i++) {
        data[formData[i].name] = formData[i].value
      }

      return data
    },

    /*
     * jQuery UI Dialog options for licensing requests
     */
    licensingOps = {
      autoOpen: false,
      height: 450,
      width: 400,
      modal: true,
      buttons: {
        Cancel: function() {
          $( this ).dialog( "close" );
        },
        "request a license": function() { 
          var data,
              response,
              button,
              row

          data = processFormData($(this).serializeArray())
          data = prepareDoc(data, "license-request")

          console.log(data)
          //TODO: getResponseHeader('Location')
          response = {}
          response.location = "/user-content/prior-art/123456789.json"

          row = $('<tr data-uri="' + response.location  + '">' +
            '<td class="name">' + data.name + '</td>' +
            '<td class="email">' + data.email + '</td>' +
            '<td class="comments">' + data.comments + '</td>' +
            '<td class="operations"></td>' +
          '</tr>')

          button = $('<button class="edit-license-request">Edit</button>')
          row.find('.operations').append(button)

          $('.prior-art-entries').append(row)

          button.click(function() {
            var obj = {},
                td = $(this).parent().parent()
            obj['src-uri'] = td.data('uri')

            td.find('td:not(.operations)').each(function(index, input) {
              var name = $(input).attr('class')
              obj[name] = $(input).text()
            })
            console.log(obj)
          })  

          $(this).get(0).reset()
          $(this).dialog("close");
        }
      }
    },

    /*
     * jQuery UI Dialog options for prior art submissions
     */
    priorArtOps = {
      autoOpen: false,
      height: 450,
      width: 400,
      modal: true,
      buttons: {
        cancel: function() {
          $(this).dialog("close");
        },
        "add prior art": function() {
          var data

          data = processFormData($(this).serializeArray())
          data = prepareDoc(data, "prior-art")

          console.log(data)

          //TODO: if exists, update
          /*
          saveDoc(data, function(data, jqXHR) {
            var srcUri = jqXHR.getResponseHeader('Location')

            //TODO: do this regardless of success?
            priorArtToRow(data, srcUri)
          */
            
            //TODO: remove this
            response = {}
            response.location = "/user-content/prior-art/123456789.json"
            priorArtToRow(data, response.location)

            $(this).get(0).reset()
            $(this).dialog("close");
          /*
          })
          */
        }
      }
    },

    priorArtToRow = function(data, srcUri) {
      var response,
          button,
          row

      //TODO: make generic
      row = $('<tr data-src-uri="' + srcUri  + '">' +
        '<td class="name">' + data.name + '</td>' +
        '<td class="email">' + data.email + '</td>' +
        '<td class="external-link">' + data['external-link'] + '</td>' +
        '<td class="comments">' + data.comments + '</td>' +
        '<td class="operations"></td>' +
      '</tr>')

      button = $('<button class="edit-prior-art">Edit</button>')
      row.find('.operations').append(button)

      $('.prior-art-entries').append(row)

      button.click(function() {
        var obj = {},
            td = $(this).parent().parent()
        obj['src-uri'] = td.data('src-uri')

        td.find('td:not(.operations)').each(function(index, input) {
          var name = $(input).attr('class')
          obj[name] = $(input).text()
        })
        console.log(obj)


        //to populate form
        /*
        $('.prior-art-form :input').each(function(index, input) {
          input.value = 'blah'
          console.log(input.name)
        })
        */

      })  
    }

// Setup patent-number click handler

$('.patent-number').click(function(e) {
  //TODO: do something else to pause this process?
  e.preventDefault();
  
  var patentNum = $(this).text()
  if (/\//.test(patentNum)) {
    patentNum = patentNum.split('/')[1]
  }
  findByPatentNum(patentNum, $(this), navigateToResult)
})

// Setup user-input dialogs
$(".licensing-form").dialog(licensingOps)
$('.request-licensing').button().click(function() {
  $(".licensing-form").dialog( "open" )
})

$('.prior-art-form').dialog(priorArtOps)
$('.add-prior-art').button().click(function() {
  $('.prior-art-form').dialog( "open" )
})

//TODO
//$('.additional-info > div').toggle()

/*
$('.additional-info').trunk8({
  //lines: 10,
  fill: '&hellip; <a id="read-more" href="#">read more</a>'
})

$('#read-more').live('click', function (event) {
  $(this).parent().trunk8('revert').append(' <a id="read-less" href="#">read less</a>');
  
  return false;
});

$('#read-less').live('click', function (event) {
  $(this).parent().trunk8();
  
  return false;
});
*/