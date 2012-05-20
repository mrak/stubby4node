Request = module.exports.Request = (req) ->
   req = req ? {}
   this.method = req.method
   this.url = req.url
   this['accept-language'] = req['accept-language']
   this['content-type'] = req['content-type']
   console.log req
   return this
