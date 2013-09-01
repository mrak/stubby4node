ce = require 'cloneextend'
fs = require 'fs'
path = require 'path'
Endpoint = require './endpoint'

NOT_FOUND = "Endpoint with the given id doesn't exist."
NO_MATCH = "Endpoint with given request doesn't exist."

module.exports.Endpoints = class Endpoints
  constructor : (data, callback = (->), datadir = process.cwd()) ->
    @datadir = datadir
    @db = {}
    @lastId = 0
    @create data, callback
    @sightings = {}

  create : (data, callback = ->) ->
    insert = (item) =>
      item = new Endpoint item, @datadir
      item.id = ++@lastId
      @db[item.id] = item
      @sightings[item.id] = 0
      callback null, ce.clone item

    if data instanceof Array
      data.forEach insert
    else if data
      insert data

  retrieve : (id, callback = ->) ->
    if not @db[id] then return callback NOT_FOUND

    callback null,  ce.clone @db[id]

  update : (id, data, callback = ->) ->
    if not @db[id] then return callback NOT_FOUND

    endpoint = new Endpoint data, @datadir
    endpoint.id = id
    @db[endpoint.id] = endpoint
    callback()

  delete : (id, callback = ->) ->
    if not @db[id] then return callback NOT_FOUND

    delete @db[id]
    callback()

  gather : (callback = ->) ->
    all = []

    for id, endpoint of @db
      all.push endpoint

    callback null, ce.clone all

  find : (data, callback = ->) ->
    for id, endpoint of @db
      continue unless endpoint.matches data
      matched = ce.clone endpoint
      return found.call @, matched, callback

    callback NO_MATCH

found = (endpoint, callback) ->
  response = endpoint.response[@sightings[endpoint.id]++ % endpoint.response.length]
  response.body = new Buffer (response.body ? 0) , 'utf8'
  response.headers['x-stubby-resource-id'] = endpoint.id

  if response.file?
    try response.body = fs.readFileSync path.resolve(@datadir, response.file)

  if parseInt response.latency
    return setTimeout (-> callback null,  response), response.latency
  else
    return callback null, response
