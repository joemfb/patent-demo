var Util = {
      urlParams: function(query) {
        //from https://stackoverflow.com/questions/901115/how-can-i-get-query-string-values-in-javascript/2880929#2880929
        var urlParams = {},
            match,
            pl     = /\+/g,  // Regex for replacing addition symbol with a space
            search = /([^&=]+)=?([^&]*)/g,
            decode = function (s) { return decodeURIComponent(s.replace(pl, " ")) }
        
        if (query === undefined) {
          query  = window.location.search.substring(1)
        }

        while ( (match = search.exec(query)) ) {
          urlParams[decode(match[1])] = decode(match[2])
        }
        return urlParams
      },

      formatDate: function(date) {
        return new Date(date).toLocaleString().split(" ")[0]
      }

    },

    UserContent = {
      findUserContent: function(uri) {
        var searchUrl

        if (uri === undefined) {
          uri = Util.urlParams().uri
        }
        searchUrl = '/v1/keyvalue?key=doc-uri&value=' + uri + '&format=json'

        $.get( searchUrl, function(data) {
          data.results.map(function(item) {
            var docUrl = '/v1/documents?uri=' + item.uri + '&format=json'

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
          row = $('<tr data-uri="' + uri  + '" data-email="' + data.email + '" data-phone="' + data.phone + '" data-created="' + data.created + '">' +
            '<td class="name">' + data.name + '</td>' +
            '<td class="formatted-date">' + new Date(data.created).toLocaleString().split(" ")[0] + '</td>' +
            '<td class="external-link">' + data['external-link'] + '</td>' +
            '<td class="comments">' + data.comments + '</td>' +
            '<td class="operations"></td>' +
          '</tr>')
        }
        else if (data.type === 'license-request') {
          selector = ".licensing"
          row = $('<tr data-uri="' + uri  + '" data-email="' + data.email + '" data-phone="' + data.phone + '" data-created="' + data.created + '">' +
            '<td class="name">' + data.name + '</td>' +
            '<td class="formatted-date">' + Util.formatDate(data.created) + '</td>' +
            '<td class="company">' + data.company + '</td>' +
            '<td class="description">' + data.description + '</td>' +
            '<td class="comments">' + data.comments + '</td>' +
            '<td class="operations"></td>' +
          '</tr>')
        }

        UserContent.populateRow(row, selector)
      },

      processInput: function(data, type) {
        var srcUri

        data = Repo.prepareDoc(data, type)
        srcUri = data.uri

        if (srcUri.length === 0) {
          Repo.saveDoc(data, function(response, status, jqXHR) {
            var url = jqXHR.getResponseHeader('Location')
            srcUri = Util.urlParams(url.split('?')[1]).uri
            UserContent.displayContent(data, srcUri)
          })
        }
        else {
          delete data.uri

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

        //this only works with single word data-* keys
        $.extend(true, obj, tr.data())

        return obj
      },

      populateRow: function(row, selector) {
        var edit,
            remove,
            existing

        edit = $('<a href="#" class="edit">edit</a>')
        remove = $('<a href="#" class="delete">delete</a>')
        contact = $('<a href="#" class="contact">contact</a>')

        row.find('.operations').append(edit)
          .append('&nbsp;|&nbsp;').append(remove)
          .append('&nbsp;|&nbsp;').append(contact)

        existing = $(selector + ' tr[data-uri="' + row.data('uri') +'"')

        if (existing.length === 0) {
          $(selector + '-entries').append(row)
        } else {
          $(existing[0]).replaceWith(row)
        }

        if ( !$(selector + '-entries').is(':visible') ) {
          $(selector + '-entries').show()
        }

        edit.click(function(e) {
          e.preventDefault()
          UserContent.edit(selector, e.target)
        })

        remove.click(function(e) {
          e.preventDefault()
          UserContent.remove(selector, e.target)
        })

        contact.click(function(e) {
          e.preventDefault()
          UserContent.contact(selector, e.target)
        })
      },

      populateForm: function(selector, obj) {
        $(selector + ' :input').each(function(index, input) {
          input.value = obj[input.name]
        })
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
            srcUri = tr.data('uri')

        $("<div/>").dialog({
          title: "Are you sure?",
          resizable: false,
          height:140,
          modal: true,
          buttons: {
            delete: function() {
              Repo.deleteDoc(srcUri, function(){
                var table = tr.parents(selector + '-entries')
                tr.remove()
                if (table.find('tbody tr').length === 0) {
                  table.hide()
                }
              })
              $( this ).dialog( "close" );
            },
            cancel: function() {
              $( this ).dialog( "close" );
            }
          }
        }).dialog("open")
      },

      contact: function(selector, target) {
        var tr = $(target).parent().parent(),
            details = $('<div>email: ' + tr.data('email') + '<br/>' + 'phone: ' + tr.data('phone') + '</div>')

        details.dialog({
          title: "Contact Details"
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
        data['doc-uri'] = Util.urlParams().uri
        data.type = type
        data.username = $('#username').text()
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
        var searchUrl = '/v1/keyvalue?element=doc-number&value=' + patentNum+ '&format=json'
        
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

        uri = Util.urlParams().uri
        result = data.results[0]

        condition = result !== null && result !== undefined
        condition = condition && result.uri !== uri
        condition = condition && /publication-reference/.test(result.matches[0].path)

        if ( condition ) {
          target.get(0).href = '/v1/documents?uri=' + encodeURIComponent(result.uri)
        } else {
          message = $('<span class="message">&nbsp;&nbsp;no results found.</span>')
          target.parent().append(message)
          message.delay(750).fadeOut()
        }

      },

      findClassifications: function() {
        $('.classification .ipc').each(function(index, item) {
          Content.findClassification($(item).data('code'), function(data) {
            Content.displayClassification(data, $(item))
          })
        })
      },

      findClassification: function(code, callback) {
        var url = '/v1/keyvalue?element=class:symbol&value=' + code + '&format=json'

        $.get(url, function(data) {
          var result = data.results[0]

          if (result !== null && result !== undefined) {
            $.get(result.href + '&format=json', function(data) {
              callback(data)
            })
          }
        })
      },

      findClassificationFromCode: function(e) {
        e.preventDefault()
        Content.findClassification($(e.target).data('code'), function(data) {
          Content.displayClassification(data, $(e.target))
        })
      },

      findClassificationFromHref: function(e) {
        e.preventDefault()
        $.get($(e.target).attr('href') + '&format=json', function(data) {
          Content.displayClassification(data, $(e.target))
        })
      },

      displayClassification: function(data, target) {
        var html = $(data.html).find('.ipc-entry'),
            wrapper

        html.find('.ipc-entry-search').click(Content.findClassificationFromCode)
        html.find('.ipc-entry-ref').click(Content.findClassificationFromHref)

        // if target is not a dialog, and target already has entries
        if (target.parents('.ui-dialog-content').length === 0 && target.parents('.ipc').find('.ipc-entry').length > 0) {
          wrapper = $('<div class="ipc-wrapper"><strong>' + data.symbol + '</strong></div>')
          wrapper.append(html).dialog({
            title: "Classification Details",
            autoOpen: false,
            height: 450,
            width: 500,
            modal: false
          }).dialog( "open" )
        } else {
          if (target.hasClass('ipc-entry-search') || target.hasClass('ipc-entry-ref')) {
            target.parent().append(html)
          } else {
            target.append(html)
          }
        }

        Content.getRelatedPatents(target.data('code'), html)
      },

      findPatentsByClassification: function(code, callback) {
        var url = '/v1/keyvalue?element=pt:classification-ipcr&attribute=code&value=' + code + '&format=json'

        $.get(url, function(data) {
          callback(data)
        })
      },

      getRelatedPatents: function(code, target) {
        Content.findPatentsByClassification(code, function(data) {
          var patents = $('<ul class="related-patents"><h3>Related Patents</h3></ul>'),
              patent,
              href

          if (data.results.length === 0) {
            return
          }

          for (var i = 0; i < data.results.length; i++) {
            Content.displayRelatedPatent(data.results[i], patents)
          }

          target.append(patents)
        })
      },

      displayRelatedPatent: function(result, patents) {
        var href = result.href,
            patent

        //exclude current doc
        if (result.uri !== Util.urlParams().uri) {
          $.get(href + '&format=json', function(details) {
            var str = '(' + details['doc-number'] + ') - ' + details.title
            patent = $('<li><a href="' + href + '" target="_blank">' + str + '</a></li>') 
            patents.append(patent)
          })
        }
      },

    }

// setup patent doc event handlers, get related content
if ( $('.patent-result').length > 0 ) {
  
  $('.date').each(function(index, item) {
    var txt = $(item).text()
    
    $(item).text( Util.formatDate(txt) )
  })

  Content.findClassifications()

  UserContent.findUserContent()

  $('.patent-number').click(function(e) {
    //TODO: do something else to pause this process?
    e.preventDefault()
    
    var patentNum = $(this).text()
    if (/\//.test(patentNum)) {
      patentNum = patentNum.split('/')[1]
    }
    Content.findByPatentNum(patentNum, $(this), Content.navigateToResult)
  })

  $(".licensing-form").dialog({
    title: "Request a License",
    autoOpen: false,
    height: 450,
    width: 400,
    modal: true,
    buttons: {
      cancel: function() {
        $(this).get(0).reset()
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
  $('.licensing-entries').hide()

  $('.prior-art-form').dialog({
    title: "Suggest Prior Art",
    autoOpen: false,
    height: 450,
    width: 400,
    modal: true,
    buttons: {
      cancel: function() {
        $(this).get(0).reset()
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
  $('.prior-art-entries').hide()
}

//add description tooltips to classification facet
if ( $('#sidebar-container').length > 0 ) {

  // from https://forum.jquery.com/topic/waiting-for-a-dom-element-to-become-available#14737000002248405
  $.fn.onAvailable = function(fn){
    var sel = this.selector,
        timer,
        self = this

    if (this.length > 0) {
      fn.call(this)
    }
    else {
      timer = setInterval(function(){
        if ($(sel).length > 0) {
          fn.call($(sel))
          clearInterval(timer)
        }
      },50)
    }
  }

  //TODO: fix these so that they fire on item display, not just on page load

  $('#facet-list-class').onAvailable(function() {
    $('#facet-list-class a[rel]').each(function(index, item) {
      if ($(item).is(":visible")) {
        Content.findClassification($(item).text(), function(data) {
          var txt = $(data.html).find('.claim-title > span').text()
          $(item).attr('title', txt)
        })
      }
    })
  })

  $('#chiclet-class .content').onAvailable(function() {
    var item = $('#chiclet-class .content'),
        code = item.text().split(" ")[1]

    Content.findClassification(code, function(data) {
      var txt = $(data.html).find('.claim-title > span').text()
      item.attr('title', txt)
    })
  })

  //ALTERNATE APPROACH: https://stackoverflow.com/questions/1225102/jquery-event-to-trigger-action-when-a-div-is-made-visible

  //FAILED ATTEMPT 1

  /*
  var _oldShow = $.fn.show;
  $.fn.show = function(speed, oldCallback) {
    return $(this).each(function() {
      var obj         = $(this),
          newCallback = function() {
            if ($.isFunction(oldCallback)) {
              oldCallback.apply(obj);
            }
            obj.trigger('afterShow');
          };

      // you can trigger a before show if you want
      obj.trigger('beforeShow');

      // now use the old function to show the element passing the new callback
      _oldShow.apply(obj, [speed, newCallback]);
    });
  }

  $('#facet-list-class').onAvailable(function () {
    console.log('onAvailable')
    $('#facet-list-class').on('afterShow', {}, function() {
      console.log('shown')
    })
  })
  */

  //FAILED ATTEMPT 2

  /*
  MutationObserver = window.MutationObserver || window.WebKitMutationObserver
  var observer = new MutationObserver(function(mutations) {
        mutations.forEach(function(mutation) {
          console.log(mutation)
          console.log('visible: ' + $(mutation.target).is(':visible'))
        })
      })
  
  $('#facet-list-class').onAvailable(function () {
    $('#facet-list-class').each(function(index, item) {
      $(item).data('test', 'yes')
      console.log(item)
      observer.observe(item, {
        subtree: true,
        childList: true,
        attributes: true
      })

    })
  })
  */
}
