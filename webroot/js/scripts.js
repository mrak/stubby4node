(function(window) {
  var stubby = window.stubby || {};
  var template = [ // eww
  '<li>',
  '  <table>',
  '     <caption><a href="<%= adminUrl %>">Endpoint <%= id %></a></caption>',
  '     <tr>',
  '        <th class="section" colspan="2">request</th>',
  '     </tr>',
  '     <tr>',
  '        <th class="property">url</th>',
  '        <td><%= request.url %></td>',
  '     </tr>',
  '     <% if(request.method) { %>',
  '     <tr>',
  '        <th class="property">method</th>',
  '        <td><%= request.method %></td>',
  '     </tr>',
  '     <% } if(request.query) { %>',
  '     <tr>',
  '        <th class="property">query</th>',
  '        <td><% print(queryParams(request.query)); %></td>',
  '     </tr>',
  '     <tr>',
  '        <th></th>',
  '        <td>',
  '           <ul>',
  '              <% _.each(_.keys(request.query), function(key) { %>',
  '              <li>',
  '                 <dt><%= key %></dt>',
  '                 <dd><%= request.query[key] %></dd>',
  '              </li>',
  '              <% }); %>',
  '           </ul>',
  '        </td>',
  '     </tr>',
  '     <% } if(request.headers) { %>',
  '     <tr>',
  '        <th class="property">headers</th>',
  '        <td>',
  '           <ul>',
  '              <% _.each(_.keys(request.headers), function(key) { %>',
  '              <li>',
  '                 <dt><%= key %></dt>',
  '                 <dd><%= request.headers[key] %></dd>',
  '              </li>',
  '              <% }); %>',
  '           </ul>',
  '        </td>',
  '     </tr>',
  '     <% } if(request.post) { %>',
  '     <tr>',
  '        <th class="property">post</th>',
  '        <td><pre><code><%= request.post %></code></pre></td>',
  '     </tr>',
  '     <% } if(request.file) { %>',
  '     <tr>',
  '        <th class="property">file</th>',
  '        <td><%= request.file %></td>',
  '     </tr>',
  '     <% } %>',
  '     <tr>',
  '        <th class="section" colspan="2">response</th>',
  '     </tr>',
  '     <% if(response.status) { %>',
  '     <tr>',
  '        <th class="property">status</th>',
  '        <td><%= response.status %></td>',
  '     </tr>',
  '     <% } if(request.headers) { %>',
  '     <tr>',
  '        <th class="property">headers</th>',
  '        <td>',
  '           <ul>',
  '              <% _.each(_.keys(response.headers), function(key) { %>',
  '              <li>',
  '                 <dt><%= key %></dt>',
  '                 <dd><%= response[0].headers[key] %></dd>',
  '              </li>',
  '              <% }); %>',
  '           </ul>',
  '        </td>',
  '     </tr>',
  '     <% } if(response[0].body) { %>',
  '     <tr>',
  '        <th class="property">body</th>',
  '        <td><pre><code><%= response[0].body %></code></pre></td>',
  '     </tr>',
  '     <% } if(response[0].file) { %>',
  '     <tr>',
  '        <th class="property">file</th>',
  '        <td><%= response[0].file %></td>',
  '     </tr>',
  '     <% } if(response[0].latency) { %>',
  '     <tr>',
  '        <th class="property">latency</th>',
  '        <td><%= response[0].latency %></td>',
  '     </tr>',
  '     <% } %>',
  '  </table>',
  '</li>',
  ].join('\n');

  function queryParams(query) {
    var result = "?";

    for (var key in query) {
      var value = query[key];

      result += encodeURIComponent(key);
      result += "=";
      result += encodeURIComponent(value);
      result += "&";
    }

    return result.replace(/\&$/, '');
  };

  var ajax = null;
  var list = null;

  function success() {
    var endpoint, _fn, _i, _len;
    var endpoints = JSON.parse(ajax.responseText);

    for (var i; i < endpoints.length; i++) {
      var endpoint = endpoints[i];

      endpoint.queryParams = queryParams;
      endpoint.adminUrl = window.location.href.replace(/status/, endpoint.id);

      var html = _.template(template)(endpoint);
      list.innerHTML += html;
    }

    hljs.initHighlighting();
  }

  function complete(e) {
    if (ajax.readyState !== 4) { return; }

    if (ajax.status === 200) { return success(); }
    else { return console.error(ajax.statusText); }
  }

  stubby.status = function() {
    list = document.getElementById('endpoints');

    ajax = new window.XMLHttpRequest();
    ajax.open('GET', '/', true);
    ajax.onreadystatechange = complete;
    ajax.send(null);
  };

  window.stubby = stubby;
})(this);
