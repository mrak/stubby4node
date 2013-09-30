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
            response: [
               latency: 3000
               body: 'contents'
               file: 'another.file'
               status: 420
               headers:
                  'access-control-allow-origin': '*'
            ]

         actual = new Endpoint data

         actualbody = actual.response[0].body.toString()
         delete actual.response[0].body
         expectedBody = data.response[0].body
         delete data.response[0].body

         assert.deepEqual actual, data
         assert expectedBody is actualbody

      it 'should default method to GET', ->
         expected = 'GET'

         actual = new Endpoint data

         assert actual.request.method is expected

      it 'should default status to 200', ->
         expected = 200

         actual = new Endpoint data

         assert actual.response[0].status is expected

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

         assert.deepEqual actual.response[0].headers, expected.response
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

         assert actual.response[0].body.toString() is expected

      it 'should get the Origin header', ->
         expected = 'http://example.org'
         data.request.headers =
            Origin: 'http://example.org'

         actual = new Endpoint data

         assert actual.request.headers.origin is expected

      it 'should define aditional Cross-Origin headers', ->
         expected = 'http://example.org'
         data.request.headers =
            Origin: 'http://example.org'
            'Access-Control-Request-Method': 'POST'
            'Access-Control-Request-Header': 'Content-Type, origin'

         actual = new Endpoint data

         assert actual.request.headers.origin is expected
         assert actual.request.headers['access-control-allow-origin'] is 'POST'
         assert actual.request.headers['access-control-request-header'] is 'Content-Type, origin'
