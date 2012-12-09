Stubby = require('../src/main').Stubby
fs = require 'fs'
http = require 'http'
qs = require 'querystring'
yaml = require 'js-yaml'
ce = require 'cloneextend'
endpointData = yaml.load (fs.readFileSync 'spec/data/e2e.yaml', 'utf8').trim()

createRequest = (context) ->
   options =
      port: 8882
      method: context.method
      path: context.url
      headers: context.requestHeaders

   if context.query?
      options.path += "?#{qs.stringify context.query}"

   request = http.request options, (response) ->
      data = ''
      response.on 'data', (chunk) ->
         data += chunk
      response.on 'end', ->
         response.data = data
         context.response = response
         context.done = true

   request.write context.post if context.post?
   request.end()
   return request

describe 'End 2 End Stubs Test Suite', ->
   sut = null
   context = null
   stopStubby = ->
      stopped = false
      sut.stop -> stopped = true
      waitsFor (-> stopped), 'stubby to stop', 1

   beforeEach ->
      if sut? then stopStubby()
      sut = new Stubby()
      context =
         done: false

      go = false

      sut.start data:endpointData, -> go = true
      waitsFor ( -> go ), 'stubby to start', 1000

   afterEach stopStubby

   describe 'basics', ->
      it 'should return a basic GET endpoint', ->
         runs ->
            context.url = '/basic/get'
            context.method = 'get'
            createRequest context

            waitsFor ( -> context.done), 'request to finish', 1000

         runs ->
            expect(context.response.statusCode).toBe 200

      it 'should return a basic PUT endpoint', ->
         runs ->
            context.url = '/basic/put'
            context.method = 'put'
            createRequest context

            waitsFor ( -> context.done ), 'request to finish', 1000

         runs ->
            expect(context.response.statusCode).toBe 200

      it 'should return a basic POST endpoint', ->
         runs ->
            context.url = '/basic/post'
            context.method = 'post'

            createRequest context
            waitsFor ( -> context.done ), 'request to finish', 1000

         runs ->
            expect(context.response.statusCode).toBe 200

      it 'should return a basic DELETE endpoint', ->
         runs ->
            context.url = '/basic/delete'
            context.method = 'delete'

            createRequest context
            waitsFor ( -> context.done ), 'request to finish', 1000

         runs ->
            expect(context.response.statusCode).toBe 200

      it 'should return a response for an endpoint with multiple methods', ->
         runs ->
            context.url = '/basic/all'
            context.method = 'delete'

            createRequest context

            waitsFor ( -> context.done ), 'all endpoint delete to finish', 1000

         runs ->
            expect(context.response.statusCode).toBe 200

         runs ->
            context =
               finished: false
               url: "/basic/all"
               method: 'get'

            createRequest context

            waitsFor ( -> context.done ), 'all endpoint get to finish', 1000

         runs ->
            expect(context.response.statusCode).toBe 200

         runs ->
            context =
               finished: false
               url: "/basic/all"
               method: 'put'

            createRequest context

            waitsFor ( -> context.done ), 'all endpoint put to finish', 1000

         runs ->
            expect(context.response.statusCode).toBe 200

         runs ->
            context =
               finished: false
               url: "/basic/all"
               method: 'post'

            createRequest context

            waitsFor ( -> context.done ), 'all endpoint post to finish', 1000

         runs ->
            expect(context.response.statusCode).toBe 200

   describe 'GET', ->
      it 'should return a body from a GET endpoint', ->
         runs ->
            context.url = '/get/body'
            context.method = 'get'

            createRequest context
            waitsFor ( -> context.done ), 'request to finish', 1000

         runs ->
            expect(context.response.data).toBe 'plain text'

      it 'should return a body from a json GET endpoint', ->
         runs ->
            context.url = '/get/json'
            context.method = 'get'

            createRequest context
            waitsFor ( -> context.done ), 'request to finish', 1000
         runs ->
            expect(context.response.data.trim()).toBe '{"property":"value"}'
            expect(context.response.headers['content-type']).toEqual 'application/json'

      it 'should return a 420 GET endpoint', ->
         runs ->
            context.url = '/get/420'
            context.method = 'get'

            createRequest context
            waitsFor ( -> context.done ), 'request to finish', 1000

         runs ->
            expect(context.response.statusCode).toBe 420

      it 'should be able to handle query params', ->
         runs ->
            context.url = '/get/query'
            context.query =
               first: 'value1 with spaces!'
               second: 'value2'
            context.method = 'get'

            createRequest context
            waitsFor ( -> context.done ), 'request to finish', 1000

         runs ->
            expect(context.response.statusCode).toBe 200


   describe 'post', ->
      it 'should be able to handle authorized posts', ->
         runs ->
            context.url = '/post/auth'
            context.method = 'post'
            context.post = 'some=data'
            context.requestHeaders =
               authorization: "Basic c3R1YmJ5OnBhc3N3b3Jk"

            createRequest context
            waitsFor ( -> context.done ), 'request to finish', 1000

         runs ->
            expect(context.response.statusCode).toBe 201
            expect(context.response.headers.location).toBe '/some/endpoint/id'
            expect(context.response.data).toBe 'resource has been created'


      it 'should be able to handle authorized posts where the yaml wasnt pre-encoded', ->
         runs ->
            context.url = '/post/auth/pair'
            context.method = 'post'
            context.post = 'some=data'
            context.requestHeaders =
               authorization: "Basic c3R1YmJ5OnBhc3N3b3JkWjBy"

            createRequest context
            waitsFor ( -> context.done ), 'request to finish', 1000

         runs ->
            expect(context.response.statusCode).toBe 201
            expect(context.response.headers.location).toBe '/some/endpoint/id'
            expect(context.response.data).toBe 'resource has been created'


   describe 'put', ->
      it 'should wait if a 2000ms latency is specified', ->
         runs ->
            context.url = '/put/latency'
            context.method = 'put'

            createRequest context
            waits 1000
            expect(context.done).toBe false
            waitsFor ( -> context.done ), 'latency-ridden request to finish', 3000

         runs ->
            expect(context.response.data).toBe 'updated'

   describe 'file use', ->
      describe 'response', ->
         it 'should handle fallback to body if specified response file cannot be found', ->
            runs ->
               context.url = '/file/body/missingfile'

               createRequest context
               waitsFor ( -> context.done ), 'body-fallback request to finish', 1000

            runs ->
               expect(context.response.data).toBe 'body contents!'

         it 'should handle file response when file can be found', ->
            runs ->
               context.url = '/file/body'

               createRequest context
               waitsFor ( -> context.done ), 'body-fallback request to finish', 1000

            runs ->
               expect(context.response.data.trim()).toBe 'file contents!'

      describe 'request', ->
         it 'should handle fallback to post if specified request file cannot be found', ->
            runs ->
               context.url = '/file/post/missingfile'
               context.method = 'post'
               context.post = 'post contents!'

               createRequest context
               waitsFor ( -> context.done ), 'post-fallback request to finish', 1000

            runs ->
               expect(context.response.statusCode).toBe 200

         it 'should handle file request when file can be found', ->
            runs ->
               context.url = '/file/post'
               context.method = 'post'
               context.post = 'file contents!'

               createRequest context
               waitsFor ( -> context.done ), 'post-fallback request to finish', 1000

            runs ->
               expect(context.response.statusCode).toBe 200
