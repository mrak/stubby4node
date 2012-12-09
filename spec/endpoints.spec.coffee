Endpoints = require('../src/models/endpoints').Endpoints
Endpoint = require('../src/models/endpoint')
sut = null

describe 'Endpoints', ->
   beforeEach ->
      sut = new Endpoints()

   describe 'operations', ->
      callback = null

      beforeEach ->
         callback = jasmine.createSpy 'callback'

      describe 'create', ->
         data = null

         beforeEach ->
            data =
               request:
                  url: ''

         it 'should assign id to entered endpoint', ->
            sut.create data, callback

            expect(sut.db[1]).toBeDefined()
            expect(sut.db[2]).not.toBeDefined()

         it 'should call callback', ->
            sut.create data, callback

            expect(callback.callCount).toBe 1

         it 'should assign ids to entered endpoints', ->
            sut.create [data, data], callback

            expect(sut.db[1]).toBeDefined()
            expect(sut.db[2]).toBeDefined()
            expect(sut.db[3]).not.toBeDefined()

         it 'should call callback for each supplied endpoint', ->
            sut.create [data, data], callback

            expect(callback.callCount).toBe 2

      describe 'retrieve', ->
         id = "any id"

         it 'should call callback with null, row if operation returns a row', ->
            row =
               request: {}
               response: {}
            sut.db[id] = row

            sut.retrieve id, callback

            expect(callback).toHaveBeenCalledWith null, row

         it 'should call callback with error msg if operation does not find item', ->
            sut.db = []

            sut.retrieve id, callback

            expect(callback).toHaveBeenCalledWith "Endpoint with the given id doesn't exist."

      describe 'update', ->
         id = "any id"
         data =
            request:
               url: ''

         it 'should call callback when database updates', ->
            sut.db[id] = {}

            sut.update id, data, callback

            expect(callback.mostRecentCall.args).toEqual []

         it 'should call callback with error msg if operation does not find item', ->

            sut.update id, data, callback

            expect(callback).toHaveBeenCalledWith "Endpoint with the given id doesn't exist."

      describe 'delete', ->
         id = "any id"

         it 'should call callback when database updates', ->
            sut.db[id] = {}

            sut.delete id, callback

            expect(callback.mostRecentCall.args).toEqual []

         it 'should call callback with error message if operation does not find item', ->
            sut.delete id, callback

            expect(callback).toHaveBeenCalledWith "Endpoint with the given id doesn't exist."

      describe 'gather', ->

         it 'should call success if operation returns some rows', ->
            data = [{},{}]
            sut.db = data

            sut.gather callback

            expect(callback.mostRecentCall.args).toEqual [data]

         it 'should call missing if operation does not find item', ->
            sut.db = []

            sut.gather callback

            expect(callback).toHaveBeenCalledWith []

      describe 'find', ->
         data =
            method: 'GET'

         it 'should call callback with null, row if operation returns a row', ->
            row = new Endpoint()
            sut.db = [row]
            sut.find data, callback

            expect(callback).toHaveBeenCalledWith null, row.response

         it 'should call callback with error if operation does not find item', ->
            sut.find data, callback

            expect(callback).toHaveBeenCalledWith "Endpoint with given request doesn't exist."

         it 'should call callback after timeout if data response has a latency', ->
            row = new Endpoint
               request: {}
               response:
                  latency: 1000

            sut.db = [row]
            sut.find data, callback
            expect(callback).not.toHaveBeenCalled()
            waitsFor (-> callback.callCount is 1), 'Callback call was never called', 1000

         describe 'request post versus file', ->
            it 'should match response with post if file is not supplied', ->
               expected = { status: 200 }
               row = new Endpoint
                  request:
                     url: '/testing'
                     post: 'the post!'
                     method: 'post'
                  response: expected
               data =
                  method: 'POST'
                  url: '/testing'
                  post: 'the post!'

               sut.db = [row]
               sut.find data, callback

               expect(callback.mostRecentCall.args[1]).toEqual expected

            it 'should match response with post file is supplied but cannot be found', ->
               expected = { status : 200 }
               row = new Endpoint
                  request:
                     url: '/testing'
                     file: 'spec/data/endpoints-nonexistant.file'
                     post: 'post data!'
                     method: 'post'
                  response: expected
               data =
                  method: 'POST'
                  url: '/testing'
                  post: 'post data!'

               sut.db = [row]
               sut.find data, callback

               expect(callback.mostRecentCall.args[1]).toEqual expected

            it 'should match response with file if file is supplied and exists', ->
               expected = { status : 200 }
               row = new Endpoint
                  request:
                     url: '/testing'
                     file: 'spec/data/endpoints.file'
                     post: 'post data!'
                     method: 'post'
                  response: expected
               data =
                  url: '/testing'
                  post: 'file contents!'
                  method: 'POST'

               sut.db = [row]
               sut.find data, callback

               expect(callback.mostRecentCall.args[1]).toEqual expected

         describe 'response body versus file', ->
            it 'should return response with body as content if file is not supplied', ->
               expected = 'the body!'
               row = new Endpoint
                  request:
                     url: '/testing'
                  response:
                     body: expected
               data =
                  url: '/testing'
                  method: 'GET'

               sut.db = [row]
               sut.find data, callback

               expect(callback.mostRecentCall.args[1].body).toBe expected

            it 'should return response with body as content if file is supplied but cannot be found', ->
               expected = 'the body!'
               row = new Endpoint
                  request:
                     url: '/testing'
                  response:
                     body: expected
                     file: 'spec/data/endpoints-nonexistant.file'
               data =
                  url: '/testing'
                  method: 'GET'

               sut.db = [row]
               sut.find data, callback

               expect(callback.mostRecentCall.args[1].body).toBe expected

            it 'should return response with file as content if file is supplied and exists', ->
               expected = 'file contents!'
               row = new Endpoint
                  request:
                     url: '/testing'
                  response:
                     body: 'body contents!'
                     file: 'spec/data/endpoints.file'
               data =
                  url: '/testing'
                  method: 'GET'

               sut.db = [row]
               sut.find data, callback

               expect(callback.mostRecentCall.args[1].body.trim()).toBe expected

         describe 'method', ->
            it 'should return response even if cases match', ->
               row = new Endpoint
                  request:
                     method: 'POST'
                  response: {}
               data =
                  method: 'POST'

               sut.db = [row]

               sut.find data, callback

               expect(callback).toHaveBeenCalledWith null, row.response

            it 'should return response even if cases do not match', ->
               row = new Endpoint
                  request:
                     method: 'post'
                  response: {}
               data =
                  method: 'POST'

               sut.db = [row]

               sut.find data, callback

               expect(callback).toHaveBeenCalledWith null, row.response

            it 'should return response if method matches any of the defined', ->
               row = new Endpoint
                  request:
                     method: ['post', 'put']
                  response: {}
               data =
                  method: 'POST'

               sut.db = [row]

               sut.find data, callback

               expect(callback).toHaveBeenCalledWith null, row.response

            it 'should call callback with error if none of the methods match', ->
               row = new Endpoint
                  request:
                     method: ['post', 'put']
                  response: {}
               data =
                  method: 'GET'

               sut.db = [row]

               sut.find data, callback

               expect(callback).toHaveBeenCalledWith "Endpoint with given request doesn't exist."


         describe 'headers', ->

            it 'should return response if all headers of request match', ->
               row = new Endpoint
                  request:
                     headers:
                        'content-type': 'application/json'
                  response: {}
               data =
                  method: 'GET'
                  headers:
                     'content-type': 'application/json'

               sut.db = [row]

               sut.find data, callback

               expect(callback).toHaveBeenCalledWith null, row.response

            it 'should call callback with error if all headers of request dont match', ->
               row = new Endpoint
                  request:
                     headers:
                        'content-type': 'application/json'
                  response: {}
               data =
                  method: 'GET'
                  headers:
                     'authentication': 'Basic gibberish:password'

               sut.db = [row]

               sut.find data, callback

               expect(callback).toHaveBeenCalledWith "Endpoint with given request doesn't exist."

         describe 'query', ->

            it 'should return response if all query of request match', ->
               row = new Endpoint
                  request:
                     query:
                        'first': 'value1'
                  response: {}
               data =
                  method: 'GET'
                  query:
                     'first': 'value1'

               sut.db = [row]

               sut.find data, callback

               expect(callback).toHaveBeenCalledWith null, row.response

            it 'should call callback with error if all query of request dont match', ->
               row = new Endpoint
                  request:
                     query:
                        'first': 'value1'
                  response: {}
               data =
                  method: 'GET'
                  query:
                     'unknown': 'good question'

               sut.db = [row]

               sut.find data, callback

               expect(callback).toHaveBeenCalledWith "Endpoint with given request doesn't exist."
