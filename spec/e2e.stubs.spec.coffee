Stubby = require('../src/main').Stubby

fs = require 'fs'
yaml = require 'js-yaml'
ce = require 'cloneextend'
endpointData = yaml.load (fs.readFileSync 'spec/data/e2e.yaml', 'utf8').trim()

waitsFor = require './helpers/waits-for'
assert = require 'assert'
createRequest = require './helpers/create-request'

describe 'End 2 End Stubs Test Suite', ->
   sut = null
   context = null
   port = 8882
   stopStubby = (finish) ->
      if sut? then return sut.stop finish
      finish()

   beforeEach (done) ->
      context =
         done: false
         port: port

      finish = ->
         sut = new Stubby()
         sut.start data:endpointData, done

      stopStubby finish

   afterEach stopStubby

   describe 'basics', ->
      it 'should return a basic GET endpoint', (done) ->
         context.url = '/basic/get'
         context.method = 'get'
         createRequest context

         waitsFor ( -> context.done), 'request to finish', 1000, ->
            assert context.response.statusCode is 200
            done()

      it 'should return a basic PUT endpoint', (done) ->
         context.url = '/basic/put'
         context.method = 'put'
         createRequest context

         waitsFor ( -> context.done ), 'request to finish', 1000, ->
            assert context.response.statusCode is 200
            done()

      it 'should return a basic POST endpoint', (done) ->
         context.url = '/basic/post'
         context.method = 'post'

         createRequest context
         waitsFor ( -> context.done ), 'request to finish', 1000, ->
            assert context.response.statusCode is 200
            done()

      it 'should return a basic DELETE endpoint', (done) ->
         context.url = '/basic/delete'
         context.method = 'delete'

         createRequest context
         waitsFor ( -> context.done ), 'request to finish', 1000, ->
            assert context.response.statusCode is 200
            done()

      it 'should return a basic HEAD endpoint', (done) ->
         context.url = '/basic/head'
         context.method = 'head'

         createRequest context
         waitsFor ( -> context.done ), 'request to finish', 1000, ->
            assert context.response.statusCode is 200
            done()

      it 'should return a response for an endpoint with multiple methods', (done) ->
         context.url = '/basic/all'
         context.method = 'delete'

         createRequest context

         waitsFor ( -> context.done ), 'all endpoint delete to finish', 1000, ->
            assert context.response.statusCode is 200

            context =
               port: port
               finished: false
               url: "/basic/all"
               method: 'get'

            createRequest context

            waitsFor ( -> context.done ), 'all endpoint get to finish', 1000, ->
               assert context.response.statusCode is 200

               context =
                  port: port
                  finished: false
                  url: "/basic/all"
                  method: 'put'

               createRequest context

               waitsFor ( -> context.done ), 'all endpoint put to finish', 1000, ->
                  assert context.response.statusCode is 200

                  context =
                     port: port
                     finished: false
                     url: "/basic/all"
                     method: 'post'

                  createRequest context

                  waitsFor ( -> context.done ), 'all endpoint post to finish', 1000, ->
                     assert context.response.statusCode is 200
                     done()

      it 'should return the CORS headers', (done) ->
         expected = 'http://example.org'

         context.url = '/basic/get'
         context.method = 'get'
         context.requestHeaders =
            'origin': expected

         createRequest context
         waitsFor ( -> context.done ), 'request to finish', 1000, ->
            headers = context.response.headers
            assert headers['access-control-allow-origin'] is expected
            assert headers['access-control-allow-credentials'] is 'true'
            done()

   describe 'GET', ->
      it 'should return a body from a GET endpoint', (done) ->
         context.url = '/get/body'
         context.method = 'get'

         createRequest context

         waitsFor ( -> context.done ), 'request to finish', 1000, ->
            assert context.response.data is 'plain text'
            done()

      it 'should return a body from a json GET endpoint', (done) ->
         context.url = '/get/json'
         context.method = 'get'

         createRequest context

         waitsFor ( -> context.done ), 'request to finish', 1000, ->
            assert context.response.data.trim() is '{"property":"value"}'
            assert context.response.headers['content-type'] is 'application/json'
            done()

      it 'should return a 420 GET endpoint', (done) ->
         context.url = '/get/420'
         context.method = 'get'

         createRequest context

         waitsFor ( -> context.done ), 'request to finish', 1000, ->
            assert context.response.statusCode is 420
            done()

      it 'should be able to handle query params', (done) ->
         context.url = '/get/query'
         context.query =
            first: 'value1 with spaces!'
            second: 'value2'
         context.method = 'get'

         createRequest context

         waitsFor ( -> context.done ), 'request to finish', 1000, ->
            assert context.response.statusCode is 200
            done()

      it 'should return 404 if query params are not matched', (done) ->
         context.url = '/get/query'
         context.query =
            first: 'invalid value'
            second: 'value2'
         context.method = 'get'

         createRequest context

         waitsFor ( -> context.done ), 'request to finish', 1000, ->
            assert context.response.statusCode is 404
            done()

   describe 'post', ->
      it 'should be able to handle authorized posts', (done) ->
         context.url = '/post/auth'
         context.method = 'post'
         context.post = 'some=data'
         context.requestHeaders =
            authorization: "Basic c3R1YmJ5OnBhc3N3b3Jk"

         createRequest context

         waitsFor ( -> context.done ), 'request to finish', 1000, ->
            assert context.response.statusCode is 201
            assert context.response.headers.location is '/some/endpoint/id'
            assert context.response.data is 'resource has been created'
            done()


      it 'should be able to handle authorized posts where the yaml wasnt pre-encoded', (done) ->
         context.url = '/post/auth/pair'
         context.method = 'post'
         context.post = 'some=data'
         context.requestHeaders =
            authorization: "Basic c3R1YmJ5OnBhc3N3b3JkWjBy"

         createRequest context

         waitsFor ( -> context.done ), 'request to finish', 1000, ->
            assert context.response.statusCode is 201
            assert context.response.headers.location is '/some/endpoint/id'
            assert context.response.data is 'resource has been created'
            done()

   describe 'put', ->
      it 'should wait if a 2000ms latency is specified', (done) ->
         @timeout 3500
         context.url = '/put/latency'
         context.method = 'put'

         createRequest context

         waitsFor ( -> context.done ), 'latency-ridden request to finish', [2000, 3000], ->
            assert context.response.data is 'updated'
            done()

   describe 'file use', ->
      describe 'response', ->
         it 'should handle fallback to body if specified response file cannot be found', (done) ->
            context.url = '/file/body/missingfile'

            createRequest context

            waitsFor ( -> context.done ), 'body-fallback request to finish', 1000, ->
               assert context.response.data is 'body contents!'
               done()

         it 'should handle file response when file can be found', (done) ->
            context.url = '/file/body'

            createRequest context

            waitsFor ( -> context.done ), 'body-fallback request to finish', 1000, ->
               assert context.response.data.trim() is 'file contents!'
               done()

      describe 'request', ->
         it 'should handle fallback to post if specified request file cannot be found', (done) ->
            context.url = '/file/post/missingfile'
            context.method = 'post'
            context.post = 'post contents!'

            createRequest context

            waitsFor ( -> context.done ), 'post-fallback request to finish', 1000, ->
               assert context.response.statusCode is 200
               done()

         it 'should handle file request when file can be found', (done) ->
            context.url = '/file/post'
            context.method = 'post'
            context.post = 'file contents!'

            createRequest context

            waitsFor ( -> context.done ), 'post-fallback request to finish', 1000, ->
               assert context.response.statusCode is 200
               done()

      ###
      describe 'match file as string', ->
         it 'should match the post body with the file properly', (done) ->
            context.url = '/file/body/matchstring'
            context.method = 'post'
            context.post = '''
            { 
               "data": [ "test" ],
               "hypermedia": [
                 "*",
                 "[a-z]{1,2}+/"
               ]
            }
            '''

            createRequest context

            waitsFor ( -> context.done ), 'body match', 1000, ->
               console.log 'STATUS ->', context.response.code
               assert context.response.code is 200
               done()
      ###
