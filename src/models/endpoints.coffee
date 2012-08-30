CLI = require('../cli')
ce = require 'cloneextend'

NOT_FOUND = "Endpoint with the given id doesn't exist."

module.exports.Endpoints = class Endpoints
   constructor : (data)->
      callback = (err, endpoint) -> CLI.notice "Loaded: #{endpoint.request.method} #{endpoint.request.url}"
      @db = {}
      @lastId = 0
      @create data, callback

   applyDefaults : (data) ->
      data.request.method ?= 'GET'
      data.request.post ?= null
      data.request.headers ?= {}
      data.response.headers ?= {}

      for prop, value of data.request.headers
         delete data.request.headers[prop]
         data.request.headers[prop.toLowerCase()] = value

      for prop, value of data.response.headers
         delete data.response.headers[prop]
         data.response.headers[prop.toLowerCase()] = value

      data.response.status = parseInt(data.response.status) or 200
      data.response.body = JSON.stringify(data.response.body) if typeof data.response.body is 'object'
      return data

   create : (data, callback) ->
      insert = (item) =>
         @applyDefaults item
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

      endpoint = @applyDefaults data
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
         if endpoint.request.url isnt data.url then continue
         if endpoint.request.post isnt data.post then continue
         if endpoint.request.method isnt data.method then continue

         headersMatch = true
         if endpoint.request.headers? and data.headers?
            for key, value of endpoint.request.headers
               if endpoint.request.headers[key] isnt data.headers[key] then headersMatch = false
         if not headersMatch then continue

         if parseInt endpoint.response.latency
            return setTimeout (-> callback null,  endpoint.response), endpoint.response.latency
         else
            return callback null, endpoint.response

      callback "Endpoint with given request doesn't exist."
