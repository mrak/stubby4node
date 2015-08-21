waitsFor = require './helpers/waits-for'
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
  beforeEach ->
    @data =
      request: {}

  describe 'matches', ->
    it 'should return regex captures for url', ->
      @data.request.url = '/capture/(.*)/$'
      endpoint = new Endpoint @data
      actual = endpoint.matches
        url: '/capture/me/'
        method: 'GET'

      assert actual.url[0] is '/capture/me/'
      assert actual.url[1] is 'me'

    it 'should return regex captures for post', ->
      @data.request.url = '/'
      @data.request.post = 'some sentence with a (\\w+) in it'
      endpoint = new Endpoint @data
      actual = endpoint.matches
        url: '/'
        method: 'GET'
        post: 'some sentence with a word in it'

      assert actual.post[1] is 'word'

    it 'should return regex captures for headers', ->
      @data.request.url = '/'
      @data.request.headers =
        'content-type': 'application/(\\w+)'
      endpoint = new Endpoint @data
      actual = endpoint.matches
        url: '/'
        method: 'GET'
        headers:
          'content-type': 'application/json'

      assert actual.headers['content-type'][1] is 'json'

    it 'should return regex captures for query', ->
      @data.request.url = '/'
      @data.request.query =
        variable: '.*'
      endpoint = new Endpoint @data
      actual = endpoint.matches
        url: '/'
        method: 'GET'
        query:
          variable: 'value'

      assert actual.query.variable[0] is 'value'

  describe 'recording', ->
    it 'should fill in a string response with the recorded endpoint', (done) ->
      waitTime = 10000
      @timeout waitTime
      @data.response = 'http://google.com'
      actual = new Endpoint @data

      waitsFor (-> actual.response[0].status is 301), "endpoint to record", waitTime, done

    it 'should fill in a string reponse with the recorded endpoint in series', (done) ->
      waitTime = 10000
      @timeout waitTime
      @data.response = ['http://google.com','http://example.com']
      actual = new Endpoint @data

      waitsFor (->
        actual.response[0].status is 301 and actual.response[1].status is 200
      ), "endpoint to record", waitTime, done

    it 'should fill in a string reponse with the recorded endpoint in series', (done) ->
      waitTime = 10000
      @timeout waitTime
      data =
        request:
          url: '/'
          method: 'GET'
          query:
            s: 'value'
        response: ['http://google.com', {
          status: 420
        }]
      actual = new Endpoint data

      waitsFor (->
        return actual.response[0].status is 301 and actual.response[1].status is 420
      ), "endpoint to record", waitTime, done

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

      actual = new Endpoint @data

      assert actual.request.method is expected

    it 'should default status to 200', ->
      expected = 200

      actual = new Endpoint @data

      assert actual.response[0].status is expected

    it 'should lower case headers properties', ->
      @data.request =
        headers: 'Content-Type': 'application/json'
      @data.response =
        headers: 'Content-Type': 'application/json'

      expected =
        request:
          'content-type': 'application/json'
        response:
          'content-type': 'application/json'

      actual = new Endpoint @data

      assert.deepEqual actual.response[0].headers, expected.response
      assert.deepEqual actual.request.headers, expected.request

    it 'should define multiple headers with same name', ->
      @data.request =
        headers: 'Content-Type': 'application/json'
      @data.response =
        headers:
          'Content-Type': 'application/json'
          'Set-Cookie': ['type=ninja', 'language=coffeescript']

      expected =
        request:
          'content-type': 'application/json'
        response:
          'content-type': 'application/json'
          'set-cookie': ['type=ninja', 'language=coffeescript']

      actual = new Endpoint @data

      assert.deepEqual actual.response[0].headers, expected.response
      assert.deepEqual actual.request.headers, expected.request

    it 'should base64 encode authorization headers if not encoded', ->
      expected = 'Basic dXNlcm5hbWU6cGFzc3dvcmQ='
      @data.request.headers =
        authorization: 'username:password'

      actual = new Endpoint @data

      assert actual.request.headers.authorization is expected

    it 'should not encode authorization headers if encoded', ->
      expected = 'Basic dXNlcm5hbWU6cGFzc3dvc='
      @data.request.headers =
        authorization: 'Basic dXNlcm5hbWU6cGFzc3dvc='

      actual = new Endpoint @data

      assert actual.request.headers.authorization is expected

    it 'should stringify object body in response', ->
      expected = '{"property":"value"}'
      @data.response =
        body: property: "value"

      actual = new Endpoint @data

      assert actual.response[0].body.toString() is expected

    it 'should get the Origin header', ->
      expected = 'http://example.org'
      @data.request.headers =
        Origin: 'http://example.org'

      actual = new Endpoint @data

      assert actual.request.headers.origin is expected

    it 'should define aditional Cross-Origin headers', ->
      expected = 'http://example.org'
      @data.request.headers =
        Origin: 'http://example.org'
        'Access-Control-Request-Method': 'POST'
        'Access-Control-Request-Headers': 'Content-Type, origin'

      actual = new Endpoint @data

      assert actual.request.headers.origin is expected
      assert actual.request.headers['access-control-request-method'] is 'POST'
      assert actual.request.headers['access-control-request-headers'] is 'Content-Type, origin'
