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
         context.body = data.trim()
         context.status = response.statusCode
         context.headers = response.headers

         if response.headers.location?
            context.location = response.headers.location

         context.finished = true

   request.write context.post if context.post?
   request.end()
   return request

xdescribe 'End 2 End Admin Test Suite', ->
   sut = null
   context = null

   beforeEach ->
      sut = new Stubby()
      context =
         finished: false

      go = false
      sut.start data:endpointData, -> go = true
      waitsFor ( -> go ), 'stubby to start', 1000

   afterEach ->
      stopped = false
      sut.stop -> stopped = true
      waitsFor (-> stopped), 'stubby to stop', 1

   it 'should react to /ping', ->
      context.url = '/ping'

      createRequest context

      waitFn = ->
         return false unless context.finished
         return context.body is 'pong'

      waitsFor waitFn, 'ping endpoint to be correct', 1000

   it 'should be able to retreive an endpoint through GET', ->
      id = 3
      endpoint = ce.clone endpointData[id-1]
      endpoint.id = id

      context.url = "/#{id}"
      context.method = 'get'

      createRequest context

      waitFn = ->
         return false unless context.finished
         returned = JSON.parse context.body
         for prop, value of endpoint.request
            if value isnt returned.request[prop] then return false
         return true

      waitsFor waitFn, 'returned endpoint to be correct', 1000

   it 'should be able to edit an endpoint through PUT', ->
      id = 2
      endpoint = ce.clone endpointData[id-1]

      runs ->
         context.url = "/#{id}"

         endpoint.request.url = '/munchkin'
         context.method = 'put'
         context.post = JSON.stringify endpoint

         createRequest context
         waitsFor (-> context.finished), 'put request to finish', 1000

      runs ->
         endpoint.id = id
         context.finished = false
         context.method = 'get'

         createRequest context

         waitFn = ->
            return false unless context.finished
            returned = JSON.parse context.body
            return returned.request.url is endpoint.request.url

         waitsFor waitFn, 'get request to finish', 1000

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

         waitFn = ->
            return false unless context.finished
            return context.status is 201
         waitsFor waitFn, 'post request to finish', 1000

      runs ->
         id = context.location.replace /localhost:8889\/([0-9]+)/, '$1'
         context =
            finished: false
            url: "/#{id}"
            method: 'get'

         createRequest context

         waitFn = ->
            return false unless context.finished
            returned = JSON.parse context.body
            return returned.request.url is endpoint.request.url

         waitsFor waitFn, 'get request to return', 1000

   it 'should be about to delete an endpoint through DELETE', ->
      runs ->
         context.url = '/2'
         context.method = 'delete'

         createRequest context

         waitFn = ->
            return false unless context.finished
            return context.status is 204
         waitsFor waitFn, 'delete request to finish', 1000

      runs ->
         context =
            finished: false
            url: "/2"
            method: 'get'

         createRequest context

         waitFn = ->
            return false unless context.finished
            return context.status is 404

         waitsFor waitFn, 'get request to return', 1000
