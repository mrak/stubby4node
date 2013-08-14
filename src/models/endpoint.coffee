fs = require 'fs'
path = require 'path'

module.exports = class Endpoint
  constructor: (endpoint = {}, datadir = process.cwd()) ->
    Object.defineProperty @, 'datadir', value: datadir

    @request = purifyRequest endpoint.request
    @response = purifyResponse endpoint.response

  matches: (request) ->
    return false unless RegExp(@request.url).test request.url
    return false unless compareHashMaps @request.headers, request.headers
    return false unless compareHashMaps @request.query, request.query

    file = null
    if @request.file?
      try file = fs.readFileSync path.resolve(@datadir, @request.file), 'utf8'

    if post = file or @request.post
      return false unless normalizeEOL(post) is normalizeEOL(request.post)

    if @request.method instanceof Array
      return false unless request.method in @request.method.map (it) -> it.toUpperCase()
    else
      return false unless @request.method.toUpperCase() is request.method

    return true

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

purifyResponse = (incoming = {}) ->
  outgoing =
    headers: purifyHeaders incoming.headers
    status: parseInt(incoming.status) or 200
    latency: parseInt(incoming.latency) or undefined
    file: incoming.file
    body: purifyBody incoming.body

  outgoing = pruneUndefined outgoing
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
  for key, value of configured
    if configured[key] isnt incoming[key] then return false
  return true

