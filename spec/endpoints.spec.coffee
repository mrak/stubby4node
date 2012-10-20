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

         actual = sut.applyDefaults data

         expect(actual.request.method).toBe expected

      it 'should default status to 200', ->
         expected = 200

         actual = sut.applyDefaults data

         expect(actual.response.status).toBe expected

      it 'should default response headers to empty object', ->
         expected = {}

         actual = sut.applyDefaults data

         expect(actual.response.headers).toEqual expected

      it 'should default request headers to empty object', ->
         expected = {}

         actual = sut.applyDefaults data

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

         actual = sut.applyDefaults data

         expect(actual.response.headers).toEqual expected.response
         expect(actual.request.headers).toEqual expected.request

      it 'should stringify object body in response', ->
         expected = '{"property":"value"}'
         data.response.body =
            property: "value"

         actual = sut.applyDefaults data

         expect(actual.response.body).toEqual expected

   describe 'operations', ->
      callback = null

      beforeEach ->
         callback = jasmine.createSpy 'callback'

      describe 'create', ->
         beforeEach ->
            spyOn(sut, 'applyDefaults').andReturn {}

         it 'should applyDefaults and run database call for each item given a list', ->
            data = [
               "item1"
               "item2"
            ]

            sut.create data, callback

            expect(sut.applyDefaults).toHaveBeenCalledWith data[0]
            expect(sut.applyDefaults).toHaveBeenCalledWith data[1]
            expect(sut.applyDefaults.callCount).toEqual data.length

         it 'should applyDefaults and run database call given one item', ->
            data = "item1"

            sut.create data, callback

            expect(sut.applyDefaults).toHaveBeenCalledWith data
            expect(sut.applyDefaults.callCount).toEqual 1

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
            spyOn(sut, 'applyDefaults').andReturn "something"

         it 'should applyDefaults to data', ->
            sut.db[id] = {}
            sut.update id, data, callback

            expect(sut.applyDefaults).toHaveBeenCalled()

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
