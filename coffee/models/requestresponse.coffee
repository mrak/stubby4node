sqlite3 = require 'sqlite3'

module.exports.RequestResponse = class RequestResponse
   constructor : () ->
      @db = new sqlite3.Database ':memory:'
      @db.run 'CREATE TABLE rNr (url,method,post,headers,status,content)', (error) ->
         if error then console.log "Can't create database!"

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

   purify : (data) ->
      data = data ? {}

      if data.method and data.method not in @methods then return null
      if data.status and not parseInt data.status then return null
      if not data.url then return null

      rNr =
         $url : data.url
         $method : data.method ? 'GET'
         $post : data.post
         $headers : data.headers ? '{}'
         $status : parseInt(data.status ? 200)
         $content : data.content

   create : (data, success, error) ->
      rNr = @purify data
      if not rNr then return error()

      @db.run @sql.create, rNr, (err) ->
         if err
            error()
         else
            success(@lastID)

   retrieve : (id, success, error, missing) ->
      @db.get @sql.retrieve, id, (err,row) ->
         if err
            error()
         else if row
            success row
         else
            missing()

   update : (id, data, success, error, missing) ->
      rNr = @purify data
      rNr["$id"] = id

      @db.run @sql.update, rNr, (err) ->
         if err
            error()
         else if @changes
            success()
         else
            missing()

   delete : (id, success, error, missing) ->
      @db.run @sql.delete, id, (err) ->
         if err
            error()
         else if @changes
            success()
         else
            missing()

   gather : (success, error, none) ->
      @db.all @sql.gather, (err, rows) ->
         if err
            error()
         else if rows.length
            success rows
         else
            none()

   find : (data, success, error, notFound) ->
      @db.get @sql.find, data, (err,row) ->
         if err then return error()
         if not row then return notFound()
         success row
