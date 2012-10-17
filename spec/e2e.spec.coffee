Stubby = require('../src/main').Stubby
fs = require 'fs'
http = require 'http'
yaml = require 'js-yaml'
endpointData = yaml.load (fs.readFileSync 'spec/data/e2e.yaml', 'utf8').trim()

createRequest = (context) ->
   context.status ?= 200
   context.body ?= ''
   context.headers ?= {}

   request = http.request context.options, (response) ->
      data = ''
      response.on 'data', (chunk) ->
         data += chunk
      response.on 'end', ->
         return unless data.trim() is context.body
         return unless response.statusCode is context.status

         for key, value of context.headers
            return unless value is response.headers[key]

         context.passed = true
   request.end()

describe 'End 2 End Test Suite', ->
   sut = null
   context = null
   options = null

   beforeEach ->
      sut = new Stubby()

      context =
         options:
            host: 'localhost'
            port: '8882'
         passed: false

      go = false
      sut.start data:endpointData, -> go = true

      waitsFor ( -> go ), 'stubby to start', 1000

   afterEach ->
      sut.stop()

   describe 'Stubs', ->
      describe 'basics', ->
         it 'should return a basic GET endpoint', ->
            context.options.path = '/basic/get'
            context.options.method = 'get'

            createRequest context
            waitsFor ( -> context.passed ), 'request to finish', 1000

         it 'should return a basic PUT endpoint', ->
            context.options.path = '/basic/put'
            context.options.method = 'put'

            createRequest context
            waitsFor ( -> context.passed ), 'request to finish', 1000

         it 'should return a basic POST endpoint', ->
            context.options.path = '/basic/post'
            context.options.method = 'post'

            createRequest context
            waitsFor ( -> context.passed ), 'request to finish', 1000

         it 'should return a basic DELETE endpoint', ->
            context.options.path = '/basic/delete'
            context.options.method = 'delete'

            createRequest context
            waitsFor ( -> context.passed ), 'request to finish', 1000

      describe 'GET', ->
         it 'should return a body from a GET endpoint', ->
            context.options.path = '/get/body'
            context.options.method = 'get'
            context.body = 'plain text'

            createRequest context
            waitsFor ( -> context.passed ), 'request to finish', 1000

         it 'should return a body from a json GET endpoint', ->
            context.options.path = '/get/json'
            context.options.method = 'get'
            context.body = '{"property":"value"}'
            context.headers = 
               'content-type': 'application/json'

            createRequest context
            waitsFor ( -> context.passed ), 'request to finish', 1000

         it 'should return a 204 GET endpoint', ->
            context.options.path = '/get/204'
            context.options.method = 'get'
            context.status = 204

            createRequest context
            waitsFor ( -> context.passed ), 'request to finish', 1000

         it 'should return a 420 GET endpoint', ->
            context.options.path = '/get/420'
            context.options.method = 'get'
            context.status = 420

            createRequest context
            waitsFor ( -> context.passed ), 'request to finish', 1000

   describe 'Admin', ->
