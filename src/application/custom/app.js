var Util = {
      urlParams: function(query) {
        //from https://stackoverflow.com/questions/901115/how-can-i-get-query-string-values-in-javascript/2880929#2880929
        var urlParams = {},
            match,
            pl     = /\+/g,  // Regex for replacing addition symbol with a space
            search = /([^&=]+)=?([^&]*)/g,
            decode = function (s) { return decodeURIComponent(s.replace(pl, " ")) }
        
        if (query == null) {
          query  = window.location.search.substring(1)
        }

        while (match = search.exec(query)) {
          urlParams[decode(match[1])] = decode(match[2])
        }
        return urlParams
      }

    },

    UserContent = {
      findUserContent: function(uri) {
        var searchUrl

        if (uri == null) {
          uri = Util.urlParams()["uri"]
        }
        searchUrl = 'keyvalue?key=uri&value=' + uri + '&format=json'

        $.get( searchUrl, function(data) {
          data.results.map(function(item) {
            var docUrl = 'documents?uri=' + item.uri + '&format=json'

            $.get( docUrl, function(data) {
              UserContent.displayContent(data, item.uri)
            })
          })
        })
      },

      displayContent: function(data, uri) {
        var selector,
            row

        if (data.type === "prior-art") {
          selector = ".prior-art"
          row = $('<tr data-src-uri="' + uri  + '">' +
            '<td class="name">' + data.name + '</td>' +
            '<td class="email">' + data.email + '</td>' +
            '<td class="external-link">' + data['external-link'] + '</td>' +
            '<td class="comments">' + data.comments + '</td>' +
            '<td class="operations"></td>' +
          '</tr>')
        }
        else if (data.type === 'license-request') {
          selector = ".licensing",
          row = $('<tr data-src-uri="' + uri  + '">' +
            '<td class="name">' + data.name + '</td>' +
            '<td class="email">' + data.email + '</td>' +
            '<td class="comments">' + data.comments + '</td>' +
            '<td class="operations"></td>' +
          '</tr>')
        }

        UserContent.populateRow(row, selector)
      },

      processInput: function(data, type) {
        var srcUri = data['src-uri']

        data = Repo.prepareDoc(data, type)

        //TODO: if exists, update
        if (srcUri === undefined) {
          Repo.saveDoc(data, function(response, status, jqXHR) {
            var url = jqXHR.getResponseHeader('Location')
            srcUri = Util.urlParams(url)['uri']
            UserContent.displayContent(data, srcUri)
          })
        }
        else {
          delete data['src-uri']

          Repo.updateDoc(data, srcUri, function(response, status, jqXHR) {
            UserContent.displayContent(data, srcUri)
          })
        }
      },

      parseRow: function(tr) {
        var obj = {}

        tr.find('td:not(.operations)').each(function(index, td) {
          var name = $(td).attr('class')
          obj[name] = $(td).text()
        })
        obj['src-uri'] = tr.data('src-uri')

        return obj
      },

      populateRow: function(row, selector) {
        var edit,
            remove,
            existing

        edit = $('<button class="edit">edit</button>')
        remove = $('<button class="delete">delete</button>')

        row.find('.operations').append(edit).append(remove)

        existing = $(selector + ' tr[data-src-uri="' + row.data('src-uri') +'"')

        if (existing.length === 0) {
          $(selector + '-entries').append(row)
        } else {
          $(existing[0]).replaceWith(row)
        }

        edit.click(function(e) {
          UserContent.edit(selector, e.target)
        })

        remove.click(function(e) {
          UserContent.remove(selector, e.target)
        })
      },

      populateForm: function(selector, obj) {
        $(selector + ' :input').each(function(index, input) {
          input.value = obj[input.name]
        })
        $(selector + ' fieldset').append('<input type="hidden" name="src-uri" id="src-uri" value="' + obj['src-uri'] +'"></input>')
      },

      edit: function(selector, target) {
        var obj = {},
            tr = $(target).parent().parent()

        obj = UserContent.parseRow(tr)

        UserContent.populateForm(selector + '-form', obj)
        $(selector + '-form').dialog( "open" )
      },

      remove: function(selector, target){
        var tr = $(target).parent().parent(),
            srcUri = tr.data('src-uri')

        $("<div/>").dialog({
          resizable: false,
          height:140,
          modal: true,
          buttons: {
            delete: function() {
              Repo.deleteDoc(srcUri, function(){
                tr.remove()
              })
              $( this ).dialog( "close" );
            },
            cancel: function() {
              $( this ).dialog( "close" );
            }
          }
        }).dialog("open")
      }

    },

    Repo = {

      //Convert the output of $.serializeArray() to an object with named properties
      processFormData: function(formData) {
        var data = {}

        for (var i = 0; i < formData.length; i++) {
          data[formData[i].name] = formData[i].value
        }

        return data
      },

      //Prepare a json document from user input
      prepareDoc: function(data, type) {
        data = Repo.processFormData(data)
        data.uri = Util.urlParams()["uri"]
        data.type = type
        data.username = $('#username').text()
        console.log(data)
        return data
      },

      saveDoc: function(data, callback) {
        data.created = new Date().toISOString()
        data['last-modified'] = new Date().toISOString()

        $.ajax({
          type: 'POST',
          url: 'documents?extension=json&directory=/user-content/' + encodeURIComponent(data.type) + '/',
          data: JSON.stringify(data),
          contentType: 'application/json',
          dataType: 'json'
        }).success(function(response, status, jqXHR) {
          callback(response, status, jqXHR)
        })
      },

      updateDoc: function(data, uri, callback) {
        data['last-modified'] = new Date().toISOString()

        $.ajax({
          type: 'PUT',
          url: 'documents?uri=' + encodeURIComponent(uri),
          data: JSON.stringify(data),
          contentType: 'application/json',
          dataType: 'json'
        }).success(function(response, status, jqXHR) {
          callback(data, status, jqXHR)
        })
      },

      deleteDoc: function(uri, callback) {
        $.ajax({
          type: 'DELETE',
          url: 'documents?uri=' + encodeURIComponent(uri),
          contentType: 'application/json',
          dataType: 'json'
        }).success(function(response, status, jqXHR) {
          callback(response, status, jqXHR)
        })
      }

    },
    
    Content = {

      //Find a Patent Document by it's publication number
      findByPatentNum: function(patentNum, target, callback) {
        var searchUrl = 'keyvalue?element=doc-number&value=' + patentNum+ '&format=json'
        
        $.get( searchUrl, function( data ) {
          callback(data, target)
        })
      },

      //Navigate to a patent document by it's publication number
      navigateToResult: function(data, target) {
        var uri,
            message,
            condition,
            result

        //TODO: check that isn't not the same doc
        uri = Util.urlParams()["uri"]
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

      }

    }

if ( $('.patent-result').length !== 0 ) {
  UserContent.findUserContent()

  // Setup patent-number click handler
  $('.patent-number').click(function(e) {
    //TODO: do something else to pause this process?
    e.preventDefault()
    
    var patentNum = $(this).text()
    if (/\//.test(patentNum)) {
      patentNum = patentNum.split('/')[1]
    }
    Content.findByPatentNum(patentNum, $(this), Content.navigateToResult)
  })

  // Setup user-input dialogs
  $(".licensing-form").dialog({
    autoOpen: false,
    height: 450,
    width: 400,
    modal: true,
    buttons: {
      cancel: function() {
        $(this).dialog("close")
      },
      "request a license": function() {
        UserContent.processInput($(this).serializeArray(), "license-request")
        $(this).get(0).reset()
        $(this).dialog("close")
      }
    }
  })
  $('.request-licensing').button().click(function() {
    $(".licensing-form").dialog( "open" )
  })

  $('.prior-art-form').dialog({
    autoOpen: false,
    height: 450,
    width: 400,
    modal: true,
    title: "Suggest Prior Art",
    buttons: {
      cancel: function() {
        $(this).dialog("close")
      },
      "add prior art": function() {
        UserContent.processInput($(this).serializeArray(), "prior-art")
        $(this).get(0).reset()
        $(this).dialog("close")
      }
    }
  })
  $('.add-prior-art').button().click(function() {
    $('.prior-art-form').dialog( "open" )
  })
}

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