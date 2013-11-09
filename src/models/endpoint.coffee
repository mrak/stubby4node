fs = require 'fs'
path = require 'path'

module.exports = class Endpoint
  constructor: (endpoint = {}, datadir = process.cwd()) ->
    Object.defineProperty @, 'datadir', value: datadir

    @request = purifyRequest endpoint.request
    @response = purifyResponse endpoint.response

  matches: (request) ->
    return false unless matchRegex @request.url, request.url
    return false unless compareHashMaps @request.headers, request.headers
    return false unless compareHashMaps @request.query, request.query

    file = null
    if @request.file?
      try file = fs.readFileSync path.resolve(@datadir, @request.file), 'utf8'

    if post = file or @request.post
      return false unless matchRegex normalizeEOL(post), normalizeEOL(request.post)

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

purifyResponse = (incoming = []) ->
  unless incoming instanceof Array
    incoming = [incoming]
  outgoing = []

  if incoming.length is 0
    incoming.push {}

  for response in incoming
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
  for key, value of configured
    return false unless matchRegex configured[key], incoming[key]
  return true

matchRegex = (compileMe, testMe) ->
  return RegExp(compileMe, 'm').test testMe
