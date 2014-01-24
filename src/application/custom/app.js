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
    findByPatentNum = function(patentNum, target, callback) {
      var searchUri = 'keyvalue?element=doc-number&value=' + patentNum+ '&format=json'
      
      $.get( searchUri, function( data ) {
        callback(data, target)
      })
    },
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
    processFormData = function(formData) {
      var data = {}

      for (var i = 0; i < formData.length; i++) {
        data[formData[i].name] = formData[i].value
      }

      return data
    },
    prepareDoc = function(data, type) {
      data.uri = urlParams()["uri"]
      data.type = type
      data.username = $('#username').text()
      return data
      //return createDoc(data, type)
    },
    createDoc = function(data) {
      $.ajax({
        type: 'POST',
        url: 'documents?extension=json&directory=/user-content/' + encodeURIComponent(data.type) + '/',
        data: JSON.stringify(data),
        contentType: 'application/json',
        dataType: 'json'
      })
    },
    licensingOps = {
      autoOpen: false,
      height: 450,
      width: 400,
      modal: true,
      buttons: {
        Cancel: function() {
          $( this ).dialog( "close" );
        },
        "Create an account": function() { 
          console.log("created an account")
        }
      }
    }
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
          var data = processFormData($(this).serializeArray()),
              row

          data = prepareDoc(data, "prior-art")
          console.log(data)

          row = "<tr>" +
            "<td>" + data.name + "</td>" +
            "<td>" + data.email + "</td>" +
            "<td>" + data.comments + "</td>" +
          "</tr>"

          console.log(row)

          $(this).get(0).reset()
          $(this).dialog("close");
        }
      }
    }

$('.patent-number').click(function(e) {
  e.preventDefault();
  
  var patentNum = $(this).text()
  if (/\//.test(patentNum)) {
    patentNum = patentNum.split('/')[1]
  }
  findByPatentNum(patentNum, $(this), navigateToResult)
})

$(".licensing-form").dialog(licensingOps)
$('.request-licensing').button().click(function() {
  $(".licensing-form").dialog( "open" )
})

$('.prior-art-form').dialog(priorArtOps)
$('.add-prior-art').button().click(function() {
  $('.prior-art-form').dialog( "open" )
})

//to populate form
/*
$('.prior-art-form :input').each(function(index, input) {
  input.value = 'blah'
  console.log(input.name)
})
*/

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