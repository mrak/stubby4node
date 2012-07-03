module.exports.Endpoint = class Endpoint
   constructor : (data)->
      success = -> console.log 'Created an endpoint'
      error = -> console.log 'The ef? Something went wrong...'
      @db = {}
      @lastId = 0
      @create data, success, error

   applyDefaults : (data) ->
      data.request.method = data.request.method ? 'GET'
      data.request.post = data.request.post ? null
      data.response.headers = data.response.headers ? {}
      data.response.status = parseInt(data.response.status) or 200
      return data

   create : (data, success, error) ->
      insert = (item)=>
         @applyDefaults item
         item.id = ++@lastId
         @db[item.id] = item
         success item.id

      if data instanceof Array
         data.forEach insert
      else if data
         insert data

   retrieve : (id, success, error, missing) ->
      if not @db[id] then return missing()

      success @db[id]

   update : (id, data, success, error, missing) ->
      if not @db[id] then return missing()

      endpoint = @applyDefaults data
      endpoint.id = id

      @db[endpoint.id] = endpoint
      success()

   delete : (id, success, error, missing) ->
      if not @db[id] then return missing()

      delete @db[id]
      success()

   gather : (success, error, none) ->
      all = []

      for id, endpoint of @db
         all.push endpoint

      if all.length is 0 then none() else success all

   find : (data, success, error, notFound) ->
      for id, endpoint of @db
         if endpoint.request.url is data.url and
         endpoint.request.post is data.post and
         endpoint.request.method is data.method
            return success endpoint.response

      notFound()
