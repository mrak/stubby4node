fs = require 'fs'
path = require 'path'
http = require 'http'
url = require 'url'
q = require 'querystring'
out = require '../console/out'

module.exports = class Endpoint
  constructor: (endpoint = {}, datadir = process.cwd()) ->
    Object.defineProperty @, 'datadir', value: datadir

    @request = purifyRequest endpoint.request
    @response = purifyResponse @, endpoint.response

  matches: (request) ->
    matches = {}
    return null unless matches.url = matchRegex @request.url, request.url
    return null unless matches.headers = compareHashMaps @request.headers, request.headers
    return null unless matches.query = compareHashMaps @request.query, request.query

    file = null
    if @request.file?
      try file = fs.readFileSync path.resolve(@datadir, @request.file), 'utf8'

    if (post = file or @request.post) and request.post
      return null unless matches.post = matchRegex normalizeEOL(post), normalizeEOL(request.post)

    if @request.method instanceof Array
      return null unless request.method in @request.method.map (it) -> it.toUpperCase()
    else
      return null unless @request.method.toUpperCase() is request.method

    return matches

record = (me, urlToRecord) ->
  recording = {}
  parsed = url.parse urlToRecord
  options =
    method: me.request.method ? 'GET'
    hostname: parsed.hostname
    headers: me.request.headers
    port: parsed.port
    path: parsed.pathname + '?'

  if parsed.query?
    options.path += parsed.query + '&'
  if me.request.query?
    options.path += q.stringify me.request.query

  recorder = http.request options, (res) ->
    recording.status = res.statusCode
    recording.headers = res.headers
    recording.body = ''

    res.on 'data', (chunk) ->
      recording.body += chunk
    res.on 'end', -> out.notice "recorded #{urlToRecord}"

  recorder.on 'error', (e) -> out.warn "error recording response #{urlToRecord}: #{e.message}"

  recording.post = new Buffer (me.request.post ? 0), 'utf8'
  if me.request.file?
    try recording.post = fs.readFileSync path.resolve(me.datadir, me.request.file)

  recorder.write recording.post
  recorder.end()

  return recording

normalizeEOL = (string) ->
  return (string.replace /\r\n/g, '\n').replace /\s*$/, ''

purifyRequest = (incoming = {}) ->
  outgoing =
    url: incoming.url
    method: incoming.method ? 'GET'
    headers: purifyHeaders incoming.headers
    query: incoming.query
    file: incoming.file
    post: incoming.post

  outgoing.headers = purifyAuthorization outgoing.headers
  outgoing = pruneUndefined outgoing
  return outgoing

purifyResponse = (me, incoming = []) ->
  unless incoming instanceof Array
    incoming = [incoming]
  outgoing = []

  if incoming.length is 0
    incoming.push {}

  for response in incoming
    if typeof response is 'string'
      outgoing.push(record me, response)
    else
      outgoing.push pruneUndefined
        headers: purifyHeaders response.headers
        status: parseInt(response.status) or 200
        latency: parseInt(response.latency) or undefined
        file: response.file
        body: purifyBody response.body

  return outgoing

purifyHeaders = (incoming) ->
  outgoing = {}
  for prop, value of incoming
    outgoing[prop.toLowerCase()] = value
  return outgoing

purifyAuthorization = (headers) ->
  return headers unless headers?.authorization

  auth = headers.authorization ? ''

  return headers unless auth.match /:/

  headers.authorization = 'Basic ' + new Buffer(auth).toString 'base64'
  return headers

purifyBody = (body = '') ->
  if typeof body is 'object'
    return JSON.stringify body
  else
    return body

pruneUndefined = (incoming) ->
  outgoing = {}
  for key, value of incoming
    outgoing[key] = value if value?
  return outgoing

setFallbacks = (endpoint) ->
  if endpoint.request.file?
    try endpoint.request.post = fs.readFileSync endpoint.request.file, 'utf8'

  if endpoint.response.file?
    try endpoint.response.body = fs.readFileSync endpoint.response.file, 'utf8'

compareHashMaps = (configured = {}, incoming = {}) ->
  headers = {}
  for key, value of configured
    return null unless headers[key] = matchRegex configured[key], incoming[key]
  return headers

matchRegex = (compileMe, testMe = '') ->
  return testMe.match RegExp(compileMe,'m')

