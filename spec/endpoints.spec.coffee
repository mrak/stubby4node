Endpoints = require('../src/models/endpoints').Endpoints
sut = null

describe 'Endpoints', ->
   beforeEach ->
      sut = new Endpoints()

   describe 'defaults', ->
      data = null

      beforeEach ->
         data =
            request : {}
            response : {}

      it 'should default method to GET', ->
         expected = 'GET'

         actual = sut.purify data

         expect(actual.request.method).toBe expected

      it 'should default status to 200', ->
         expected = 200

         actual = sut.purify data

         expect(actual.response.status).toBe expected

      it 'should default response headers to empty object', ->
         expected = {}

         actual = sut.purify data

         expect(actual.response.headers).toEqual expected

      it 'should default request headers to empty object', ->
         expected = {}

         actual = sut.purify data

         expect(actual.request.headers).toEqual expected

      it 'should lower case headers properties', ->
         data.request.headers =
            'Content-Type': 'application/json'
         data.response.headers =
            'Content-Type': 'application/json'

         expected =
            request:
               'content-type': 'application/json'
            response:
               'content-type': 'application/json'

         actual = sut.purify data

         expect(actual.response.headers).toEqual expected.response
         expect(actual.request.headers).toEqual expected.request

      it 'should stringify object body in response', ->
         expected = '{"property":"value"}'
         data.response.body =
            property: "value"

         actual = sut.purify data

         expect(actual.response.body).toEqual expected

   describe 'operations', ->
      callback = null

      beforeEach ->
         callback = jasmine.createSpy 'callback'

      describe 'create', ->
         beforeEach ->
            spyOn(sut, 'purify').andReturn {}

         it 'should purify and run database call for each item given a list', ->
            data = [
               "item1"
               "item2"
            ]

            sut.create data, callback

            expect(sut.purify).toHaveBeenCalledWith data[0]
            expect(sut.purify).toHaveBeenCalledWith data[1]
            expect(sut.purify.callCount).toEqual data.length

         it 'should purify and run database call given one item', ->
            data = "item1"

            sut.create data, callback

            expect(sut.purify).toHaveBeenCalledWith data
            expect(sut.purify.callCount).toEqual 1

         it "should call callback with null, id if database creates item", ->
            id = 1 #sut.db empty, so starts at 1
            data = {}

            sut.create data, callback

            expect(callback).toHaveBeenCalledWith null, id: id

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
         data = "some data"

         beforeEach ->
            spyOn(sut, 'purify').andReturn "something"

         it 'should purify to data', ->
            sut.db[id] = {}
            sut.update id, data, callback

            expect(sut.purify).toHaveBeenCalled()

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
         data = {}

         it 'should call callback with null, row if operation returns a row', ->
            row =
               request: {}
               response: {}
            sut.db = [row]
            sut.find data, callback

            expect(callback).toHaveBeenCalledWith null, row.response

         it 'should call callback with error if operation does not find item', ->
            sut.find data, callback

            expect(callback).toHaveBeenCalledWith "Endpoint with given request doesn't exist."

         it 'should call callback after timeout if data response has a latency', ->
            row =
               request: {}
               response:
                  latency: 1000

            sut.db = [row]
            sut.find data, callback
            expect(callback).not.toHaveBeenCalled()
            waitsFor (-> callback.callCount is 1), 'Callback call was never called', 1000

         describe 'request post versus file', ->
            it 'should match response with post if file is not supplied', ->
               expected = {expected: "object"}
               row =
                  request:
                     url: '/testing'
                     post: 'the post!'
                  response: expected
               data =
                  url: '/testing'
                  post: 'the post!'

               sut.db = [row]
               sut.find data, callback

               expect(callback.mostRecentCall.args[1]).toBe expected

            it 'should match response with post file is supplied but cannot be found', ->
               expected = {expected: "object"}
               row =
                  request:
                     url: '/testing'
                     file: 'spec/data/endpoints-nonexistant.file'
                     post: 'post data!'
                  response: expected
               data =
                  url: '/testing'
                  post: 'post data!'

               sut.db = [row]
               sut.find data, callback

               expect(callback.mostRecentCall.args[1]).toBe expected

            it 'should match response with file if file is supplied and exists', ->
               expected = {expected: "object"}
               row =
                  request:
                     url: '/testing'
                     file: 'spec/data/endpoints.file'
                     post: 'post data!'
                  response: expected
               data =
                  url: '/testing'
                  post: 'file contents!'

               sut.db = [row]
               sut.find data, callback

               expect(callback.mostRecentCall.args[1]).toBe expected

         describe 'response body versus file', ->
            it 'should return response with body as content if file is not supplied', ->
               expected = 'the body!'
               row =
                  request:
                     url: '/testing'
                  response:
                     body: expected
               data =
                  url: '/testing'

               sut.db = [row]
               sut.find data, callback

               expect(callback.mostRecentCall.args[1].body).toBe expected

            it 'should return response with body as content if file is supplied but cannot be found', ->
               expected = 'the body!'
               row =
                  request:
                     url: '/testing'
                  response:
                     body: expected
                     file: 'spec/data/endpoints-nonexistant.file'
               data =
                  url: '/testing'

               sut.db = [row]
               sut.find data, callback

               expect(callback.mostRecentCall.args[1].body).toBe expected

            it 'should return response with file as content if file is supplied and exists', ->
               expected = 'file contents!'
               row =
                  request:
                     url: '/testing'
                  response:
                     body: 'body contents!'
                     file: 'spec/data/endpoints.file'
               data =
                  url: '/testing'

               sut.db = [row]
               sut.find data, callback

               expect(callback.mostRecentCall.args[1].body.trim()).toBe expected

         describe 'headers', ->

            it 'should return response if all headers of request match', ->
               row =
                  request:
                     headers:
                        'content-type': 'application/json'
                  response: {}
               data =
                  headers:
                     'content-type': 'application/json'

               sut.db = [row]

               sut.find data, callback

               expect(callback).toHaveBeenCalledWith null, row.response

            it 'should call callback with error if all headers of request dont match', ->
               row =
                  request:
                     headers:
                        'content-type': 'application/json'
                  response: {}
               data =
                  headers:
                     'authentication': 'Basic gibberish:password'

               sut.db = [row]

               sut.find data, callback

               expect(callback).toHaveBeenCalledWith "Endpoint with given request doesn't exist."

            it 'should return response if no headers are on endpoint or response', ->
               row =
                  request: {}
                  response: {}
               data = {}

               sut.db = [row]

               sut.find data, callback

               expect(callback).toHaveBeenCalledWith null, row.response

         describe 'query', ->

            it 'should return response if all query of request match', ->
               row =
                  request:
                     query:
                        'first': 'value1'
                  response: {}
               data =
                  query:
                     'first': 'value1'

               sut.db = [row]

               sut.find data, callback

               expect(callback).toHaveBeenCalledWith null, row.response

            it 'should call callback with error if all query of request dont match', ->
               row =
                  request:
                     query:
                        'first': 'value1'
                  response: {}
               data =
                  query:
                     'unknown': 'good question'

               sut.db = [row]

               sut.find data, callback

               expect(callback).toHaveBeenCalledWith "Endpoint with given request doesn't exist."

            it 'should return response if no query are on endpoint or response', ->
               row =
                  request: {}
                  response: {}
               data = {}

               sut.db = [row]

               sut.find data, callback

               expect(callback).toHaveBeenCalledWith null, row.response

