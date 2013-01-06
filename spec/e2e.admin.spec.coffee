Stubby = require('../src/main').Stubby
Endpoint = require '../src/models/endpoint'

fs = require 'fs'
yaml = require 'js-yaml'
ce = require 'cloneextend'
endpointData = yaml.load (fs.readFileSync 'spec/data/e2e.yaml', 'utf8').trim()

waitsFor = require './helpers/waits-for'
assert = require 'assert'
createRequest = require './helpers/create-request'

describe 'End 2 End Admin Test Suite', ->
   sut = null
   context = null
   port = 8889
   stopStubby = (finish) ->
      if sut? then return sut.stop finish
      finish()

   beforeEach (done) ->
      context =
         done: false
         port: port

      finish = ->
         sut = new Stubby()
         sut.start {data:endpointData}, done

      stopStubby finish

   afterEach stopStubby

   it 'should react to /ping', (done) ->
         context.url = '/ping'

         createRequest context

         waitsFor ( -> context.done), 'request to finish', 1000, ->
            assert context.response.data is 'pong'
            done()

   it 'should be able to retreive an endpoint through GET', (done) ->
      id = 3
      endpoint = new Endpoint endpointData[id-1]
      endpoint.id = id

      context.url = "/#{id}"
      context.method = 'get'

      createRequest context

      waitsFor ( -> context.done), 'request to finish', 1000, ->
         returned = JSON.parse context.response.data
         for prop, value of endpoint.request
            assert value is returned.request[prop]
         done()

   it 'should be able to edit an endpoint through PUT', (done) ->
      id = 2
      endpoint = new Endpoint endpointData[id-1]

      context.url = "/#{id}"

      endpoint.request.url = '/munchkin'
      context.method = 'put'
      context.post = JSON.stringify endpoint

      createRequest context

      waitsFor (-> context.done), 'put request to finish', 1000, ->
         endpoint.id = id
         context.done = false
         context.method = 'get'

         createRequest context

         waitsFor (-> context.done), 'get request to finish', 1000, ->
            returned = JSON.parse context.response.data
            assert returned.request.url is endpoint.request.url
            done()

   it 'should be about to create an endpoint through POST', (done) ->
      endpoint =
         request:
            url: '/posted/endpoint'
         response:
            status: 200

      context.url = '/'
      context.method = 'post'
      context.post = JSON.stringify endpoint

      createRequest context

      waitsFor ( -> context.done), 'post request to finish', 1000, ->

         assert context.response.statusCode is 201

         id = context.response.headers.location.replace /localhost:8889\/([0-9]+)/, '$1'
         context =
            port: port
            done: false
            url: "/#{id}"
            method: 'get'

         createRequest context

         waitsFor ( -> context.done), 'get request to finish', 1000, ->
            returned = JSON.parse context.response.data
            assert returned.request.url is endpoint.request.url
            done()

   it 'should be about to delete an endpoint through DELETE', (done) ->
      context.url = '/2'
      context.method = 'delete'

      createRequest context

      waitsFor ( -> context.done), 'delete request to finish', 1000, ->
         assert context.response.statusCode is 204

         context =
            port: port
            done: false
            url: "/2"
            method: 'get'

         createRequest context

         waitsFor ( -> context.done), 'get request to finish', 1000, ->
            context.response.statusCode is 404
            done()
