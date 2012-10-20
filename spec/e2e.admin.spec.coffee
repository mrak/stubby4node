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
         context.finished = true

   request.write context.post if context.post?
   request.end()
   return request

describe 'End 2 End Admin Test Suite', ->
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
      context.url = "/#{id}"

      endpoint.request.url = '/munchkin'
      context.method = 'put'
      context.post = JSON.stringify endpoint

      createRequest context
      waitsFor (-> context.finished), 'put request to finish', 1000

      endpoint.id = id
      context.finished = false
      context.method = 'get'

      createRequest context

      waitFn = ->
         return false unless context.finished
         returned = JSON.parse context.body
         return returned.url is endpoint.url

      waitsFor waitFn, 'get request to finish', 1000
