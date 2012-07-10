Endpoint = require('../src/models/endpoint').Endpoint
sut = null

describe 'Endpoint', ->
   beforeEach ->
      sut = new Endpoint()

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

      it 'should default headers to empty object', ->
         expected = {}

         actual = sut.applyDefaults data

         expect(actual.response.headers).toEqual expected

   describe 'operations', ->
      success = null
      error = null
      missing = null
      beforeEach ->
         success = jasmine.createSpy 'success'
         error   = jasmine.createSpy 'error'
         missing = jasmine.createSpy 'missing'

      describe 'create', ->
         beforeEach ->
            spyOn(sut, 'applyDefaults').andReturn "a non-emtpy value"
         it 'should applyDefaults and run database call for each item given a list', ->
            data = [
               "item1"
               "item2"
            ]

            sut.create data, success

            expect(sut.db[1]).toBe data.item1
            expect(sut.db[2]).toBe data.item2
            expect(sut.applyDefaults.callCount).toEqual data.length

         it 'should applyDefaults and run database call given one item', ->
            data = "item1"

            sut.create data, success

            expect(sut.applyDefaults.callCount).toEqual 1

         it "should call success with id if database creates item", ->
            id = 1 #sut.db empty, so starts at 1
            data = {}

            sut.create data, success

            expect(success).toHaveBeenCalledWith id

      describe 'retrieve', ->
         id = "any id"

         it 'should call success if operation returns a row', ->
            row =
               request: {}
               response: {}
            sut.db[id] = row

            sut.retrieve id, success, missing

            expect(success).toHaveBeenCalledWith row

         it 'should call missing if operation does not find item', ->
            sut.db = []

            sut.retrieve id, success, missing

            expect(missing).toHaveBeenCalled()

      describe 'update', ->
         id = "any id"
         data = "some data"

         beforeEach ->
            spyOn(sut, 'applyDefaults').andReturn "something"

         it 'should applyDefaults to data', ->
            sut.db[id] = {}
            missing = ->
            sut.update id, data, success, missing

            expect(sut.applyDefaults).toHaveBeenCalled()

         it 'should call success when database updates', ->
            sut.db[id] = {}
            success = jasmine.createSpy()

            sut.update id, data, success

            expect(success).toHaveBeenCalled()

         it 'should call missing if operation does not find item', ->

            sut.update id, data, success, missing

            expect(missing).toHaveBeenCalled()

      describe 'delete', ->
         id = "any id"

         it 'should call success when database updates', ->
            sut.db[id] = {}
            success = jasmine.createSpy()

            sut.delete id, success

            expect(success).toHaveBeenCalled()

         it 'should call missing if operation does not find item', ->
            sut.delete id, success, missing

            expect(missing).toHaveBeenCalled()

      describe 'gather', ->
         none = null

         beforeEach ->
            none = jasmine.createSpy 'none'

         it 'should call success if operation returns some rows', ->

            sut.gather success, none

            expect(success).toHaveBeenCalled

         it 'should call missing if operation does not find item', ->
            sut.db = []

            sut.gather success, none

            expect(none).toHaveBeenCalled()

      describe 'find', ->
         data = {}

         it 'should call success if operation returns a row', ->
            row =
               request: {}
               response: {}
            sut.db = [row]
            sut.find data, success, missing

            expect(success).toHaveBeenCalledWith row.response

         it 'should call missing if operation does not find item', ->
            sut.find data, success, missing

            expect(missing).toHaveBeenCalled()

