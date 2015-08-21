sut = null
assert = require 'assert'

describe 'contract', ->
  data = null

  beforeEach ->
    sut = require('../src/models/contract')
    data =
      request :
        url : "something"
        method : 'POST'
        query :
          first: 'value1'
          second: 'value2'
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
        latency: 5000

  it 'should return no errors for valid data', ->
    result = sut data

    assert result is null

  it 'should return no errors for an array of valid data', ->
    data = [data, data]
    result = sut data

    assert result is null

  it 'should return an array of errors when multiple problems are found', ->
    expected = [[
      "'response.status' must be integer-like."
    ],[
      "'request.url' is required."
      "'request.method' must be one of GET,PUT,POST,HEAD,PATCH,TRACE,DELETE,CONNECT,OPTIONS."
      "'response.headers', if supplied, must be an object."
    ]]

    data.response.status = "a string"
    data2 =
      request:
        method: "INVALID"
      response:
        headers: []

    results = sut [data, data2]
    assert.deepEqual results, expected

  it 'should return array of errors for an array with an invalid datum', ->
    invalid = {}
    data = [data, invalid]
    result = sut data

    assert result.length is 1

  describe 'request', ->
    it 'should return error when missing', ->
      expected = ["'request' object is required."]
      data.request = null
      actual = sut data
      assert.deepEqual actual, expected

      data.request = undefined
      actual = sut data

      assert.deepEqual actual, expected

    describe 'query', ->
      it 'should have no errors when absent', ->
        data.request.query = null
        result = sut data

        assert result is null

        data.request.query = undefined
        result = sut data

        assert result is null

      it 'cannot be an array', ->
        expected = ["'request.query', if supplied, must be an object."]

        data.request.query = ['one', 'two']
        actual = sut data

        assert.deepEqual actual, expected

      it 'cannot be a string', ->
        expected = ["'request.query', if supplied, must be an object."]

        data.request.query = 'one'
        actual = sut data

        assert.deepEqual actual, expected

    describe 'headers', ->
      it 'should have no errors when absent', ->
        data.request.headers = null
        result = sut data
        assert result is null

        data.request.headers = undefined
        result = sut data
        assert result is null

      it 'cannot be an array', ->
        expected = ["'request.headers', if supplied, must be an object."]

        data.request.headers = ['one', 'two']
        actual = sut data

        assert.deepEqual actual, expected

      it 'cannot be a string', ->
        expected = ["'request.headers', if supplied, must be an object."]

        data.request.headers = 'one'
        actual = sut data

        assert.deepEqual actual, expected

    describe 'url', ->
      it 'should return error for a missing url', ->
        expected = ["'request.url' is required."]
        data.request.url = null
        result = sut data

        assert.deepEqual result, expected

        data.request.url = undefined
        result = sut data
        assert.deepEqual result, expected

    describe 'method', ->
      it 'should accept an array of methods', ->
        data.request.method = ['put', 'post', 'get']

        result = sut data
        assert result is null

      it 'should accept lowercase methods', ->
        data.request.method = 'put'

        result = sut data
        assert result is null

      it 'should have no errors for a missing method (defaults to GET)', ->
        data.request.method = null
        result = sut data
        assert result is null

        data.request.method = undefined
        result = sut data
        assert result is null

      it 'should return error if method isnt HTTP 1.1', ->
        expected = ["'request.method' must be one of GET,PUT,POST,HEAD,PATCH,TRACE,DELETE,CONNECT,OPTIONS."]

        data.request.method = 'QUEST'
        result = sut data

        assert.deepEqual result, expected

    it 'should return no errors for a missing post field', ->
      data.request.post = null
      result = sut data
      assert result is null

      data.request.post = undefined
      result = sut data
      assert result is null

  describe 'response', ->
    it 'should be optional', ->
      data.response = null
      result = sut data
      assert result is null

      data.response = undefined
      result = sut data
      assert result is null

    it 'should be acceptable as a string', ->
      data.response = 'http://www.google.com'
      result = sut data
      assert result is null

    it 'should be acceptable as an array', ->
      data.response = [
        status: 200
      ]
      result = sut data
      assert result is null

    it 'should return errors if a response in the array is invalid', ->
      expected = ["'response.status' must be < 600."]
      data.response = [{
        status: 200
      },{
        status: 800
      }]
      result = sut data
      assert.deepEqual result, expected

    describe 'headers', ->
      it 'should return no errors when absent', ->
        data.response.headers = null
        result = sut data
        assert result is null

        data.response.headers = undefined
        result = sut data
        assert result is null

      it 'cannot be an array', ->
        expected = ["'response.headers', if supplied, must be an object."]

        data.response.headers = ['one', 'two']
        actual = sut data

        assert.deepEqual actual, expected

      it 'cannot be a string', ->
        expected = ["'response.headers', if supplied, must be an object."]

        data.response.headers = 'one'
        actual = sut data

        assert.deepEqual actual, expected

    describe 'status', ->
      it 'should return no erros when absent', ->
        data.response.status = null
        result = sut data
        assert result is null

        data.response.status = undefined
        result = sut data
        assert result is null

      it 'should return no errors when it is a number', ->
        data.response.status = 400
        result = sut data
        assert result is null

      it 'should return no errors when it is a string of a number', ->
        data.response.status = "400"
        result = sut data
        assert result is null

      it 'cannot be a string that is not a number', ->
        expected = ["'response.status' must be integer-like."]
        data.response.status = "string"
        actual = sut data
        assert.deepEqual actual, expected

      it 'cannot be an object', ->
        expected = ["'response.status' must be integer-like."]
        data.response.status = {'property':'value'}
        actual = sut data
        assert.deepEqual actual, expected

      it 'should return erros when less than 100', ->
        expected = ["'response.status' must be >= 100."]
        data.response.status = 99
        actual = sut data
        assert.deepEqual actual, expected

      it 'should return erros when greater than or equal to 500', ->
        expected = ["'response.status' must be < 600."]
        data.response.status = 666
        actual = sut data
        assert.deepEqual actual, expected

    describe 'latency', ->
      it 'should return no errors when it is a number', ->
        data.response.latency = 4000
        result = sut data
        assert result is null

      it 'should return no errors when it a string representation of a number', ->
        data.response.latency = "4000"
        result = sut data
        assert result is null

      it 'should return an error when a string cannot be parsed as a number', ->
        expected = ["'response.latency' must be integer-like."]
        data.response.latency = "fred"
        actual = sut data
        assert.deepEqual actual, expected

    it 'should return no errors for an empty body', ->
      delete data.response.body
      result = sut data
      assert result is null

      data.response.body = undefined
      result = sut data
      assert result is null
