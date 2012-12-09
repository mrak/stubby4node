Stubby = require('../src/main').Stubby
fs = require 'fs'
http = require 'http'
yaml = require 'js-yaml'
ce = require 'cloneextend'
endpointData = yaml.load (fs.readFileSync 'spec/data/e2e.yaml', 'utf8').trim()

createRequest = (context) ->
   options =
      port: 8889
      method: context.method
      path: context.url

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

describe 'End 2 End Admin Test Suite', ->
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

   it 'should react to /ping', ->
      runs ->
         context.url = '/ping'

         createRequest context

         waitsFor ( -> context.done), 'request to finish', 1000

      runs ->
         expect(context.response.data).toBe 'pong'

   it 'should be able to retreive an endpoint through GET', ->
      id = 3
      endpoint = ce.clone endpointData[id-1]
      runs ->
         endpoint.id = id

         context.url = "/#{id}"
         context.method = 'get'

         createRequest context

         waitsFor ( -> context.done), 'request to finish', 1000

      runs ->
         returned = JSON.parse context.response.data
         for prop, value of endpoint.request
            expect(value).toBe returned.request[prop]

   it 'should be able to edit an endpoint through PUT', ->
      id = 2
      endpoint = ce.clone endpointData[id-1]

      runs ->
         context.url = "/#{id}"

         endpoint.request.url = '/munchkin'
         context.method = 'put'
         context.post = JSON.stringify endpoint

         createRequest context
         waitsFor (-> context.done), 'put request to finish', 1000

      runs ->
         endpoint.id = id
         context.done = false
         context.method = 'get'

         createRequest context

         waitsFor (-> context.done), 'get request to finish', 1000

      runs ->
         returned = JSON.parse context.response.data
         expect(returned.request.url).toBe endpoint.request.url

   it 'should be about to create an endpoint through POST', ->
      endpoint =
         request:
            url: '/posted/endpoint'
         response:
            status: 200

      runs ->
         context.url = '/'
         context.method = 'post'
         context.post = JSON.stringify endpoint

         createRequest context

         waitsFor ( -> context.done), 'post request to finish', 1000

      runs ->
         expect(context.response.statusCode).toBe 201

      runs ->
         id = context.response.headers.location.replace /localhost:8889\/([0-9]+)/, '$1'
         context =
            done: false
            url: "/#{id}"
            method: 'get'

         createRequest context

         waitsFor ( -> context.done), 'get request to finish', 1000

      runs ->
         returned = JSON.parse context.response.data
         expect(returned.request.url).toBe endpoint.request.url

   it 'should be about to delete an endpoint through DELETE', ->
      runs ->
         context.url = '/2'
         context.method = 'delete'

         createRequest context

         waitsFor ( -> context.done), 'delete request to finish', 1000

      runs ->
         expect(context.response.statusCode).toBe 204

      runs ->
         context =
            done: false
            url: "/2"
            method: 'get'

         createRequest context

         waitsFor ( -> context.done), 'get request to finish', 1000

      runs ->
         expect(context.response.statusCode).toBe 404
