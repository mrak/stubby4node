stubby = window.stubby ?= {}

template = """
<li>
   <table>
      <caption><a href="<%= adminUrl %>">Endpoint <%= id %></a></caption>
      <tr>
         <th class="section" colspan="2">request</th>
      </tr>
      <tr>
         <th>url</th>
         <td><%= request.url %></td>
      </tr>
      <% if(request.method) { %>
      <tr>
         <th>method</th>
         <td><%= request.method %></td>
      </tr>
      <% } if(request.query) { %>
      <tr>
         <th>query</th>
         <td><% print(queryParams(request.query)); %></td>
      </tr>
      <tr>
         <th></th>
         <td>
            <ul>
               <% _.each(_.keys(request.query), function(key) { %>
               <li>
                  <dt><%= key %></dt>
                  <dd><%= request.query[key] %></dd>
               </li>
               <% }); %>
            </ul>
         </td>
      </tr>
      <% } if(request.headers) { %>
      <tr>
         <th>headers</th>
         <td>
            <ul>
               <% _.each(_.keys(request.headers), function(key) { %>
               <li>
                  <dt><%= key %></dt>
                  <dd><%= request.headers[key] %></dd>
               </li>
               <% }); %>
            </ul>
         </td>
      </tr>
      <% } if(request.post) { %>
      <tr>
         <th>post</th>
         <td><%= request.post %></td>
      </tr>
      <% } if(request.file) { %>
      <tr>
         <th>file</th>
         <td><%= request.file %></td>
      </tr>
      <% } %>
      <tr>
         <th class="section" colspan="2">response</th>
      </tr>
      <% if(response.status) { %>
      <tr>
         <th>status</th>
         <td><%= response.status %></td>
      </tr>
      <% } if(request.headers) { %>
      <tr>
         <th>headers</th>
         <td>
            <ul>
               <% _.each(_.keys(response.headers), function(key) { %>
               <li>
                  <dt><%= key %></dt>
                  <dd><%= response.headers[key] %></dd>
               </li>
               <% }); %>
            </ul>
         </td>
      </tr>
      <% } if(response.body) { %>
      <tr>
         <th>body</th>
         <td><%= response.body %></td>
      </tr>
      <% } if(response.file) { %>
      <tr>
         <th>file</th>
         <td><%= response.file %></td>
      </tr>
      <% } if(response.latency) { %>
      <tr>
         <th>latency</th>
         <td><%= response.latency %></td>
      </tr>
      <% } %>
   </table>
</li>
"""

queryParams = (query) ->
   result = "?"

   for key, value of query
      result += encodeURIComponent key
      result += "="
      result += encodeURIComponent value
      result += "&"

   return result.replace /\&$/, ''

ajax = null
list = null

success = ->
   endpoints = JSON.parse ajax.responseText
   for endpoint in endpoints
      do (endpoint) ->
         endpoint.queryParams = queryParams
         endpoint.adminUrl = window.location.href.replace /status/, endpoint.id
         html = _.template template, endpoint
         list.innerHTML += html

complete = (e) ->
   return unless ajax.readyState is 4

   if ajax.status is 200
      success()
   else
      console.error ajax.statusText

stubby.status = ->
   list = document.getElementById 'endpoints'

   ajax = new window.XMLHttpRequest()
   ajax.open 'GET', '/', true
   ajax.onreadystatechange = complete
   ajax.send null
