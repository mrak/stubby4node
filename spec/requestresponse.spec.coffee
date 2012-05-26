RnR = require('../src/models/requestresponse').RequestResponse
sut = null

describe 'RequestResponse', ->
   beforeEach ->
      sut = new RnR()

   describe 'purify', ->
      data = null

      beforeEach ->
         data =
            request:
               url : '/'
            response: {}

      it 'should return null if no url specified', ->
         expected = null
         data.request.url = null
         actual = sut.purify data

         expect(actual).toBe expected

      it 'should return null for unknown HTTP method', ->
         expected = null
         data.request.method = 'unknown method'

         actual = sut.purify data

         expect(actual).toBe expected

      it 'should return null for non-integer status codes', ->
         expected = null
         data.response.status = 'word'

         actual = sut.purify data

         expect(actual).toBe expected

      it 'should stringify headers if supplied as object', ->
         data.response.headers =
            'Content-Type' : 'application/json'
         expected = '{"Content-Type":"application/json"}'

         actual = sut.purify data

         expect(actual.$headers).toEqual expected


      describe 'defaults', ->
         it 'should default method to GET', ->
            expected = 'GET'

            actual = sut.purify data

            expect(actual.$method).toBe expected

         it 'should default status to 200', ->
            expected = 200

            actual = sut.purify data

            expect(actual.$status).toBe expected

         it 'should default headers to empty JSON', ->
            expected = '{}'

            actual = sut.purify data

            expect(actual.$headers).toBe expected

   describe 'operations', ->
      success = null
      error = null
      missing = null
      beforeEach ->
         success = jasmine.createSpy 'success'
         error   = jasmine.createSpy 'error'
         missing = jasmine.createSpy 'missing'

      describe 'create', ->
         it 'should puify and run database call for each item given a list', ->
            spyOn sut.db, 'run'
            spyOn(sut, 'purify').andReturn "a non-emtpy value"
            data = [
               "item1"
               "item2"
            ]

            sut.create data

            expect(sut.db.run.callCount).toEqual data.length
            expect(sut.purify.callCount).toEqual data.length

         it 'should puify and run database call given one item', ->
            spyOn sut.db, 'run'
            spyOn(sut, 'purify').andReturn "a non-emtpy value"
            data = "item1"

            sut.create data

            expect(sut.db.run.callCount).toEqual 1
            expect(sut.purify.callCount).toEqual 1

         it "should call error if database can't create", ->
            sut.db.run = (something, anything, callback) -> callback("an error message")
            spyOn(sut, 'purify').andReturn "a non-emtpy value"
            data = "item1"

            sut.create data, success, error

            expect(error).toHaveBeenCalled()
            expect(success).not.toHaveBeenCalled()

         it "should call success with id if database creates item", ->
            id = "created id"
            sut.db.run = (something, anything, callback) -> callback.call(lastID: id)
            spyOn(sut, 'purify').andReturn "a non-emtpy value"
            data = "item1"

            sut.create data, success, error

            expect(error).not.toHaveBeenCalled()
            expect(success).toHaveBeenCalledWith id

      describe 'retrieve', ->
         id = "any id"
         it 'should call error if operation errors out', ->
            sut.db.get = (something, anything, callback) -> callback("an error generated")

            sut.retrieve id, success, error, missing

            expect(error).toHaveBeenCalled()

         it 'should call success if operation returns a row', ->
            row = 'any row'
            spyOn(sut, 'construct').andReturn row
            sut.db.get = (something, anything, callback) -> callback(null, row)

            sut.retrieve id, success, error, missing

            expect(success).toHaveBeenCalledWith row

         it 'should call missing if operation does not find item', ->
            sut.db.get = (something, anything, callback) -> callback(null, null)

            sut.retrieve id, success, error, missing

            expect(missing).toHaveBeenCalled()

      describe 'update', ->
         id = "any id"
         data = "some data"

         beforeEach ->
            spyOn(sut, 'purify').andReturn "something"

         it 'should purify data', ->

            sut.update id, data, success, error

            expect(sut.purify).toHaveBeenCalled()

         it 'should call error when database errors out', ->
            sut.db.run = (something, anything, callback) -> callback("an error")

            sut.update id, data, success, error

            expect(error).toHaveBeenCalled()

         it 'should call success when database updates', ->
            sut.db.run = (something, anything, callback) ->
               callback.call(changes:1)

            sut.update id, data, success, error

            expect(success).toHaveBeenCalled()

         it 'should call missing if operation does not find item', ->
            sut.db.run = (something, anything, callback) -> callback.call(changes : 0)

            sut.update id, data, success, error, missing

            expect(missing).toHaveBeenCalled()

      describe 'delete', ->
         id = "any id"

         it 'should call error when database errors out', ->
            sut.db.run = (something, anything, callback) -> callback("an error")

            sut.delete id, success, error

            expect(error).toHaveBeenCalled()

         it 'should call success when database updates', ->
            sut.db.run = (something, anything, callback) ->
               callback.call(changes:1)

            sut.delete id, success, error

            expect(success).toHaveBeenCalled()

         it 'should call missing if operation does not find item', ->
            sut.db.run = (something, anything, callback) -> callback.call(changes : 0)

            sut.delete id, success, error, missing

            expect(missing).toHaveBeenCalled()

      describe 'gather', ->
         none = null

         beforeEach ->
            none = jasmine.createSpy 'none'

         it 'should call error if operation errors out', ->
            sut.db.all = (something, callback) -> callback("an error generated")

            sut.gather success, error, none

            expect(error).toHaveBeenCalled()

         it 'should call success if operation returns some rows', ->
            rows = ['some', 'rows']
            spyOn(sut, 'construct').andReturn rows
            sut.db.all = (something, callback) -> callback(null, rows)

            sut.gather success, error, none

            expect(success).toHaveBeenCalledWith rows

         it 'should call missing if operation does not find item', ->
            rows = []
            sut.db.all = (something, callback) -> callback(null, rows)

            sut.gather success, error, none

            expect(none).toHaveBeenCalled()

      describe 'find', ->
         data = "some data"
         it 'should call error if operation errors out', ->
            sut.db.get = (something, anything, callback) -> callback("an error generated")

            sut.find data, success, error, missing

            expect(error).toHaveBeenCalled()

         it 'should call success if operation returns a row', ->
            row = 'any row'
            sut.db.get = (something, anything, callback) -> callback(null, row)

            sut.find data, success, error, missing

            expect(success).toHaveBeenCalledWith row

         it 'should call missing if operation does not find item', ->
            sut.db.get = (something, anything, callback) -> callback(null, null)

            sut.find data, success, error, missing

            expect(missing).toHaveBeenCalled()

