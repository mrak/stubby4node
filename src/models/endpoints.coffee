ce = require 'cloneextend'
fs = require 'fs'

NOT_FOUND = "Endpoint with the given id doesn't exist."

module.exports.Endpoints = class Endpoints
   constructor : (data, callback = ->) ->
      @db = {}
      @lastId = 0
      @create data, callback

   purify : (data) ->
      data.response ?= {}

      item =
         request:
            url: data.request.url
            method: data.request.method ? 'GET'
            headers: data.request.headers
            query: data.request.query
         response:
            headers: data.response.headers
            status: parseInt(data.response.status) or 200

      @purifyBody item, data
      item.request.file = data.request.file if data.request.file?
      item.request.post = data.request.post if data.request.post?

      item.response.latency = data.response.latency if data.response.latency?
      item.response.file = data.response.file if data.response.file?

      for prop, value of item.request.headers
         delete item.request.headers[prop]
         item.request.headers[prop.toLowerCase()] = value

      for prop, value of item.response.headers
         delete item.response.headers[prop]
         item.response.headers[prop.toLowerCase()] = value
      return item

   purifyBody : (item, data) ->
      if data.response.body?
         if typeof data.response.body is 'object'
            item.response.body = JSON.stringify data.response.body if data.response.body?
         else
            item.response.body = data.response.body

   create : (data, callback) ->
      insert = (item) =>
         item = @purify item
         item.id = ++@lastId
         @db[item.id] = ce.clone item
         callback null, ce.clone item

      if data instanceof Array
         data.forEach insert
      else if data
         insert data

   retrieve : (id, callback) ->
      if not @db[id] then return callback NOT_FOUND

      callback null,  ce.clone @db[id]

   update : (id, data, callback) ->
      if not @db[id] then return callback NOT_FOUND

      endpoint = @purify data
      endpoint.id = id

      @db[endpoint.id] = ce.clone endpoint
      callback()

   delete : (id, callback) ->
      if not @db[id] then return callback NOT_FOUND

      delete @db[id]
      callback()

   gather : (callback) ->
      all = []

      for id, endpoint of @db
         all.push endpoint

      callback ce.clone all

   find : (data, callback) ->
      for id, endpoint of @db
         setFallbacks(endpoint)

         continue if endpoint.request.url isnt data.url
         continue unless compareHashMaps endpoint.request.headers, data.headers
         continue unless compareHashMaps endpoint.request.query, data.query
         continue if endpoint.request.post? and endpoint.request.post isnt data.post

         if endpoint.request.method instanceof Array
            continue unless data.method in endpoint.request.method.map (it) -> it.toUpperCase()
         else
            continue if endpoint.request.method?.toUpperCase() isnt data.method

         return found endpoint, callback

      callback "Endpoint with given request doesn't exist."

found = (endpoint, callback) ->
   if parseInt endpoint.response.latency
      return setTimeout (-> callback null,  endpoint.response), endpoint.response.latency
   else
      return callback null, endpoint.response

setFallbacks = (endpoint) ->
   if endpoint.request.file?
      try endpoint.request.post = (fs.readFileSync endpoint.request.file, 'utf8').trim()

   if endpoint.response.file?
      try endpoint.response.body = fs.readFileSync endpoint.response.file, 'utf8'

compareHashMaps = (configured = {}, incoming = {}) ->
   for key, value of configured
      if configured[key] isnt incoming[key] then return false
   return true

