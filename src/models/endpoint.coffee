sqlite3 = require 'sqlite3'

module.exports.Endpoint = class Endpoint
   constructor : (file) ->
      success = -> console.log "Successfully in row from file"
      error = -> console.error "Unable to parse file"

      @db = new sqlite3.Database ':memory:'
      @db.run '''
         CREATE TABLE endpoints (
            url TEXT,
            method TEXT,
            post TEXT,
            headers TEXT,
            status NUMBER,
            content TEXT
         )
         ''', (err) =>
            if err then return console.error "Can't create database!"
            if file? then @create file, success, error

   sql :
      create   : 'INSERT INTO endpoints VALUES ($url,$method,$post,$headers,$status,$content)'
      retrieve : 'SELECT rowid AS id, * FROM endpoints WHERE id = ?'
      update   : 'UPDATE endpoints SET url=$url,method=$method,post=$post,headers=$headers,status=$status,content=$content WHERE rowid = $id'
      delete   : 'DELETE FROM endpoints WHERE rowid = ?'
      gather   : 'SELECT rowid AS id, * FROM endpoints'
      find     : 'SELECT headers,status,content FROM endpoints WHERE url = $url AND method is $method AND post is $post'

   construct : (data) =>
      if data instanceof Array
         toReturn = []
         for row in data
            toReturn.push @unflatten row
         return toReturn
      else
         return @unflatten row

   unflatten: (data) ->
      endpoint =
         id : data.id
         request :
            url : data.url
            method : data.method
            post : data.post
         response :
            headers : JSON.parse data.headers
            content : data.content
            status : data.status

   flatten4SQL : (data) ->
      row =
         $url : data.request.url
         $method : data.request.method ? 'GET'
         $post : data.request.post
         $headers : JSON.stringify(data.response.headers ? {})
         $status : parseInt(data.response.status) or 200
         $content : data.response.content

   create : (data, success, error) ->
      insert = (item) =>
         endpoint = @flatten4SQL item
         if not endpoint then return error()

         @db.run @sql.create, endpoint, (err) ->
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
      endpoint = @flatten4SQL data
      endpoint["$id"] = id

      @db.run @sql.update, endpoint, (err) ->
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
