RnR = require('../src/models/requestresponse').RequestResponse
sut = null

describe 'RequestResponse', ->
   beforeEach ->
      sut = new RnR()

   describe 'purify', ->
      data = null

      beforeEach ->
         data = url : '/'

      it 'should return null if no url specified', ->
         expected = null
         data.url = null
         actual = sut.purify data

         expect(actual).toBe expected

      it 'should return null for unknown HTTP method', ->
         expected = null
         data.method = 'unknown method'

         actual = sut.purify data

         expect(actual).toBe expected

      it 'should return null for non-integer status codes', ->
         expected = null
         data.status = 'word'

         actual = sut.purify data

         expect(actual).toBe expected

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
