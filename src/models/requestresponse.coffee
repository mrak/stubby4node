sqlite3 = require 'sqlite3'

module.exports.RequestResponse = class RequestResponse
   constructor : (file) ->
      success = -> console.log "Successfully in row from file"
      error = -> console.error "Unable to parse file"

      @db = new sqlite3.Database ':memory:'
      @db.run 'CREATE TABLE rNr (url,method,post,headers,status,content)', (err) =>
         if err then return console.error "Can't create database!"
         if file? then @create file, success, error

   methods : [
      'GET'
      'PUT'
      'POST'
      'HEAD'
      'TRACE'
      'DELETE'
      'CONNECT'
      'OPTIONS'
   ]

   sql :
      create   : 'INSERT INTO rNr VALUES ($url,$method,$post,$headers,$status,$content)'
      retrieve : 'SELECT rowid AS id, * FROM rNr WHERE id = ?'
      update   : 'UPDATE rNr SET url=$url,method=$method,post=$post,headers=$headers,status=$status,content=$content WHERE rowid = $id'
      delete   : 'DELETE FROM rNr WHERE rowid = ?'
      gather   : 'SELECT rowid AS id, * FROM rNr'
      find     : 'SELECT headers,status,content FROM rNr WHERE url = $url AND method is $method AND post is $post'

   construct : (data) ->
      if data instanceof Array
         toReturn = []
         for row in data
            toReturn.push
               id : row.id
               request :
                  url : row.url
                  method : row.method
                  post : row.post
               response :
                  headers : JSON.parse row.headers
                  content : row.content
                  status : row.status
         return toReturn
      else
         toReturn =
            id : data.id
            request :
               url : data.url
               method : data.method
               post : data.post
            response :
               headers : JSON.parse data.headers
               content : data.content
               status : data.status

   purify : (data) ->
      data = data ? {}

      if data.request.method and data.request.method not in @methods then return null
      if data.response.status and not parseInt data.response.status then return null
      if not data.request.url then return null
      if typeof data.response.headers is 'object' then data.response.headers = JSON.stringify data.response.headers

      rNr =
         $url : data.request.url
         $method : data.request.method ? 'GET'
         $post : data.request.post
         $headers : data.response.headers ? '{}'
         $status : parseInt(data.response.status ? 200)
         $content : data.response.content

   create : (data, success, error) ->
      insert = (item) =>
         rNr = @purify item
         if not rNr then return error()

         @db.run @sql.create, rNr, (err) ->
            if err then return error()
            success(@lastID)

      if data instanceof Array
         data.forEach insert
      else
         insert data

   retrieve : (id, success, error, missing) ->
      @db.get @sql.retrieve, id, (err,row) =>
         if err then return error()
         if row
            return success @construct row
         missing()

   update : (id, data, success, error, missing) ->
      rNr = @purify data
      rNr["$id"] = id

      @db.run @sql.update, rNr, (err) ->
         if err then return error()
         if @changes then return success()
         missing()

   delete : (id, success, error, missing) ->
      @db.run @sql.delete, id, (err) ->
         if err then return error()
         if @changes then return success()
         missing()

   gather : (success, error, none) ->
      @db.all @sql.gather, (err, rows) =>
         if err then return error()
         if rows.length then return success @construct rows
         none()

   find : (data, success, error, notFound) ->
      @db.get @sql.find, data, (err,row) ->
         if err then return error()
         if not row then return notFound()
         success row
