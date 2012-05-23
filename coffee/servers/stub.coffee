RnR = require('../models/requestresponse').RequestResponse

module.exports.Stub = class Stub
   constructor : ->
      @RnR = new RnR()
      @qs = require 'querystring'

   server : (request, response) =>
      post = null
      request.on 'data', (chunk) ->
         post = post ? ''
         post += chunk

      request.on 'end', () ->
         post = @qs.parse post if post?
         responseData = @RnR.find post
