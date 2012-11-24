stubby = window.stubby ?= {}

Handlebars.registerHelper 'queryParams', (request) ->
   result = "?"

   for key, value of request.query
      result += encodeURIComponent key
      result += "="
      result += encodeURIComponent value
      result += "&"

   return result.replace /\&$/, ''

Handlebars.registerHelper 'enumerate', (context, options) ->
   result = ""

   for key, value of context
      result += options.fn { key: key, value: value }

   return result

ajax = null
list = null
template = null

success = ->
   endpoints = JSON.parse ajax.responseText
   for endpoint in endpoints
      do (endpoint) ->
         endpoint.adminUrl = window.location.href.replace /status/, endpoint.id
         html = template endpoint
         list.innerHTML += html

complete = (e) ->
   return unless ajax.readyState is 4

   if ajax.status is 200
      success()
   else
      console.error ajax.statusText

stubby.status = ->
   template = Handlebars.compile document.getElementById('endpoint-template').innerText
   list = document.getElementById 'endpoints'

   ajax = new window.XMLHttpRequest()
   ajax.open 'GET', '/', true
   ajax.onreadystatechange = complete
   ajax.send null
