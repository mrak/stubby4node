ce = require 'cloneextend'
fs = require 'fs'
path = require 'path'
Endpoint = require './endpoint'

NOT_FOUND = "Endpoint with the given id doesn't exist."

module.exports.Endpoints = class Endpoints
   constructor : (data, callback = (->), datadir = process.cwd()) ->
      @datadir = datadir
      @db = {}
      @lastId = 0
      @create data, callback

   create : (data, callback) ->
      insert = (item) =>
         item = new Endpoint item, @datadir
         item.id = ++@lastId
         @db[item.id] = item
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

      endpoint = new Endpoint data, @datadir
      endpoint.id = id
      @db[endpoint.id] = endpoint
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
         continue unless endpoint.matches data

         matched = ce.clone endpoint
         if matched.response.file?
            try matched.response.body = fs.readFileSync path.resolve(@datadir, matched.response.file), 'utf8'

         return found matched, callback

      callback "Endpoint with given request doesn't exist."

found = (endpoint, callback) ->
   if parseInt endpoint.response.latency
      return setTimeout (-> callback null,  endpoint.response), endpoint.response.latency
   else
      return callback null, endpoint.response
