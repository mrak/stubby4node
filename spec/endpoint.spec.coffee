Endpoint = require '../src/models/endpoint'


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

         expect(compareObjects actual, data).toBe true

      it 'should default method to GET', ->
         expected = 'GET'

         actual = new Endpoint data

         expect(actual.request.method).toBe expected

      it 'should default status to 200', ->
         expected = 200

         actual = new Endpoint data

         expect(actual.response.status).toBe expected

      it 'should not default response headers', ->
         actual = new Endpoint data

         expect(actual.response.headers).not.toBeDefined()

      it 'should not default request headers', ->
         actual = new Endpoint data

         expect(actual.request.headers).not.toBeDefined()

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

         expect(actual.response.headers).toEqual expected.response
         expect(actual.request.headers).toEqual expected.request

      it 'should base64 encode authorization headers if not encoded', ->
         expected = 'Basic dXNlcm5hbWU6cGFzc3dvcmQ='
         data.request.headers =
            authorization: 'username:password'

         actual = new Endpoint data

         expect(actual.request.headers.authorization).toBe expected

      it 'should not encode authorization headers if encoded', ->
         expected = 'Basic dXNlcm5hbWU6cGFzc3dvc='
         data.request.headers =
            authorization: 'Basic dXNlcm5hbWU6cGFzc3dvc='

         actual = new Endpoint data

         expect(actual.request.headers.authorization).toBe expected

      it 'should stringify object body in response', ->
         expected = '{"property":"value"}'
         data.response =
            body: property: "value"

         actual = new Endpoint data

         expect(actual.response.body).toEqual expected
