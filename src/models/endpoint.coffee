CLI = require('../cli').CLI

module.exports.Endpoint = class Endpoint
   constructor : (data)->
      success = (endpoint) -> CLI.notice "Loaded: #{endpoint.request.method} #{endpoint.request.url}"
      @db = {}
      @lastId = 0
      @create data, success

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

   create : (data, success) ->
      insert = (item)=>
         @applyDefaults item
         item.id = ++@lastId
         @db[item.id] = item
         success item

      if data instanceof Array
         data.forEach insert
      else if data
         insert data

   retrieve : (id, success, missing) ->
      if not @db[id] then return missing()

      success @db[id]

   update : (id, data, success, missing) ->
      if not @db[id] then return missing()

      endpoint = @applyDefaults data
      endpoint.id = id

      @db[endpoint.id] = endpoint
      success()

   delete : (id, success, missing) ->
      if not @db[id] then return missing()

      delete @db[id]
      success()

   gather : (success, none) ->
      all = []

      for id, endpoint of @db
         all.push endpoint

      if all.length is 0 then none() else success all

   find : (data, success, notFound) ->
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
            return setTimeout (-> success endpoint.response), endpoint.response.latency
         else
            return success endpoint.response

      notFound()
