sut = null

describe 'contract', ->
   data = null

   beforeEach ->
      sut = require('../src/models/contract')
      data =
         request :
            url : "something"
            method : 'POST'
            post : 'form data'
            headers :
               property : 'value'
            auth:
               username : 'Afmrak'
               password : 'stubby'
         response :
            headers : 
               property : 'value'
            status : 204
            body : 'success!'

   it 'should return true for valid data', ->
      result = sut data

      expect(result).toBeTruthy()

   it 'should return true for an array of valid data', ->
      data = [data, data]
      result = sut data

      expect(result).toBeTruthy()

   it 'should return false for an array with an invalid datum', ->
      invalid = {}
      data = [data, invalid]
      result = sut data

      expect(result).toBeFalsy()

   describe 'request', ->
      it 'is required', ->
         data.request = null
         result = sut data
         expect(result).toBeFalsy()

         data.request = undefined
         result = sut data
         expect(result).toBeFalsy()

      describe 'headers', ->
         it 'can be absent', ->
            data.request.headers = null
            result = sut data
            expect(result).toBeTruthy()

            data.request.headers = undefined
            result = sut data
            expect(result).toBeTruthy()

         it 'cannot be an array', ->
            data.request.headers = ['one', 'two']
            result = sut data
            expect(result).toBeFalsy()

         it 'cannot be a string', ->
            data.request.headers = 'one'
            result = sut data
            expect(result).toBeFalsy()

      describe 'url', ->
         it 'should return false for a missing url', ->
            data.request.url = null
            result = sut data
            expect(result).toBeFalsy()

            data.request.url = undefined
            result = sut data
            expect(result).toBeFalsy()

      describe 'method', ->
         it 'should allow a missing method (defaults to GET)', ->
            data.request.method = null
            result = sut data
            expect(result).toBeTruthy()

            data.request.method = undefined
            result = sut data
            expect(result).toBeTruthy()

         it 'should fail if method isnt HTTP 1.1', ->
            data.request.method = 'QUEST'
            result = sut data
            expect(result).toBeFalsy()

      it 'should allow a missing post field', ->
         data.request.post = null
         result = sut data
         expect(result).toBeTruthy()

         data.request.post = undefined
         result = sut data
         expect(result).toBeTruthy()

   describe 'response', ->
      it 'is required', ->
         data.response = null
         result = sut data
         expect(result).toBeFalsy()

         data.response = undefined
         result = sut data
         expect(result).toBeFalsy()

      describe 'headers', ->
         it 'can be absent', ->
            data.response.headers = null
            result = sut data
            expect(result).toBeTruthy()

            data.response.headers = undefined
            result = sut data
            expect(result).toBeTruthy()

         it 'cannot be an array', ->
            data.response.headers = ['one', 'two']
            result = sut data
            expect(result).toBeFalsy()

         it 'cannot be a string', ->
            data.response.headers = 'one'
            result = sut data
            expect(result).toBeFalsy()

      describe 'status', ->
         it 'is not required', ->
            data.response.status = null
            result = sut data
            expect(result).toBeTruthy()

            data.response.status = undefined
            result = sut data
            expect(result).toBeTruthy()

         it 'can be a number', ->
            data.response.status = 400
            result = sut data
            expect(result).toBeTruthy()

         it 'can be a string of a number', ->
            data.response.status = "400"
            result = sut data
            expect(result).toBeTruthy()

         it 'can be a string that is not a number', ->
            data.response.status = "string"
            result = sut data
            expect(result).toBeFalsy()

         it 'cannot be an object', ->
            data.response.status = {'property':'value'}
            result = sut data
            expect(result).toBeFalsy()

      it 'should allow empty body', ->
         data.response.body = null
         result = sut data
         expect(result).toBeTruthy()

         data.response.body = undefined
         result = sut data
         expect(result).toBeTruthy()
