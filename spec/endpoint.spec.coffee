Endpoint = require '../src/models/endpoint'
assert = require 'assert'

compareOneWay = (left, right) ->
   for own key, value of left
      continue unless right[key] is value

      if typeof value is 'object'
         continue unless compareObjects value, right[key]

      return false

   return true

compareObjects = (one, two) ->
   return compareOneWay(one,two) and compareOneWay(two,one)


describe 'Endpoint', ->
   data = null

   beforeEach ->
      data =
         request: {}

   describe 'constructor', ->
      it 'should at least copy over valid data', ->
         data =
            request:
               url: '/'
               method: 'post'
               query:
                  variable: 'value'
               headers:
                  header: 'string'
               post: 'data'
               file: 'file.txt'
            response:
               latency: 3000
               body: 'contents'
               file: 'another.file'
               status: 420
               headers:
                  'access-control-allow-origin': '*'

         actual = new Endpoint data

         actualbody = actual.response.body.toString()
         delete actual.response.body
         expectedBody = data.response.body
         delete data.response.body

         assert.deepEqual actual, data
         assert expectedBody is actualbody

      it 'should default method to GET', ->
         expected = 'GET'

         actual = new Endpoint data

         assert actual.request.method is expected

      it 'should default status to 200', ->
         expected = 200

         actual = new Endpoint data

         assert actual.response.status is expected

      xit 'should not default response headers', ->
         actual = new Endpoint data

         assert actual.response.headers is undefined

      xit 'should not default request headers', ->
         actual = new Endpoint data

         assert actual.request.headers is undefined

      it 'should lower case headers properties', ->
         data.request =
            headers: 'Content-Type': 'application/json'
         data.response =
            headers: 'Content-Type': 'application/json'

         expected =
            request:
               'content-type': 'application/json'
            response:
               'content-type': 'application/json'

         actual = new Endpoint data

         assert.deepEqual actual.response.headers, expected.response
         assert.deepEqual actual.request.headers, expected.request

      it 'should base64 encode authorization headers if not encoded', ->
         expected = 'Basic dXNlcm5hbWU6cGFzc3dvcmQ='
         data.request.headers =
            authorization: 'username:password'

         actual = new Endpoint data

         assert actual.request.headers.authorization is expected

      it 'should not encode authorization headers if encoded', ->
         expected = 'Basic dXNlcm5hbWU6cGFzc3dvc='
         data.request.headers =
            authorization: 'Basic dXNlcm5hbWU6cGFzc3dvc='

         actual = new Endpoint data

         assert actual.request.headers.authorization is expected

      it 'should stringify object body in response', ->
         expected = '{"property":"value"}'
         data.response =
            body: property: "value"

         actual = new Endpoint data

         assert actual.response.body.toString() is expected
