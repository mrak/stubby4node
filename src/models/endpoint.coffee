sqlite3 = require 'sqlite3'

module.exports.Endpoint = class Endpoint
   constructor : (file) ->
      success = -> console.log "Successfully in row from file"
      error = -> console.error "Unable to parse file"

      @db = new sqlite3.Database ':memory:'
      @db.run '''
         CREATE TABLE rNr (
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
      create   : 'INSERT INTO rNr VALUES ($url,$method,$post,$headers,$status,$content)'
      retrieve : 'SELECT rowid AS id, * FROM rNr WHERE id = ?'
      update   : 'UPDATE rNr SET url=$url,method=$method,post=$post,headers=$headers,status=$status,content=$content WHERE rowid = $id'
      delete   : 'DELETE FROM rNr WHERE rowid = ?'
      gather   : 'SELECT rowid AS id, * FROM rNr'
      find     : 'SELECT headers,status,content FROM rNr WHERE url = $url AND method is $method AND post is $post'

   construct : (data) =>
      if data instanceof Array
         toReturn = []
         for row in data
            toReturn.push @unflattenFromSQL row
         return toReturn
      else
         return @unflattenFromSQL row

   unflattenFromSQL: (data) ->
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

   flatten4SQL : (data) ->
      rNr =
         $url : data.request.url
         $method : data.request.method ? 'GET'
         $post : data.request.post
         $headers : JSON.stringify(data.response.headers ? {})
         $status : parseInt(data.response.status) or 200
         $content : data.response.content

   create : (data, success, error) ->
      insert = (item) =>
         rNr = @flatten4SQL item
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
      rNr = @flatten4SQL data
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
