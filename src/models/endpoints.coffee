ce = require 'cloneextend'
fs = require 'fs'
Endpoint = require './endpoint'

NOT_FOUND = "Endpoint with the given id doesn't exist."

module.exports.Endpoints = class Endpoints
   constructor : (data, callback = ->) ->
      @db = {}
      @lastId = 0
      @create data, callback

   create : (data, callback) ->
      insert = (item) =>
         item = new Endpoint item
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

      endpoint = new Endpoint data
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

