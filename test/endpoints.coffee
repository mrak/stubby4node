Endpoints = require('../src/models/endpoints').Endpoints
Endpoint = require('../src/models/endpoint')
assert = require 'assert'
bufferEqual = require 'buffer-equal'
waitsFor = require './helpers/waits-for'
sut = null

describe 'Endpoints', ->
  beforeEach ->
    sut = new Endpoints()

  describe 'operations', ->
    callback = null

    beforeEach ->
      callback = @sandbox.spy()

    describe 'create', ->
      data = null

      beforeEach ->
        data =
          request:
            url: ''

      it 'should assign id to entered endpoint', ->
        sut.create data, callback

        assert sut.db[1] isnt undefined
        assert sut.db[2] is undefined

      it 'should call callback', ->
        sut.create data, callback

        assert callback.calledOnce

      it 'should assign ids to entered endpoints', ->
        sut.create [data, data], callback

        assert sut.db[1] isnt undefined
        assert sut.db[2] isnt undefined
        assert sut.db[3] is undefined

      it 'should call callback for each supplied endpoint', ->
        sut.create [data, data], callback

        assert callback.calledTwice

    describe 'retrieve', ->
      id = "any id"

      it 'should call callback with null, row if operation returns a row', ->
        row =
          request: {}
          response: {}
        sut.db[id] = row

        sut.retrieve id, callback

        assert callback.args[0][0] is null
        assert callback.args[0][1]

      it 'should call callback with error msg if operation does not find item', ->
        sut.db = []

        sut.retrieve id, callback

        assert callback.calledWith "Endpoint with the given id doesn't exist."

    describe 'update', ->
      id = "any id"
      data =
        request:
          url: ''

      it 'should call callback when database updates', ->
        sut.db[id] = {}

        sut.update id, data, callback

        assert callback.calledWithExactly()

      it 'should call callback with error msg if operation does not find item', ->

        sut.update id, data, callback

        assert callback.calledWith "Endpoint with the given id doesn't exist."

    describe 'delete', ->
      id = "any id"

      it 'should call callback when database updates', ->
        sut.db[id] = {}

        sut.delete id, callback

        assert callback.calledWithExactly()

      it 'should call callback with error message if operation does not find item', ->
        sut.delete id, callback

        assert callback.calledWith "Endpoint with the given id doesn't exist."

    describe 'gather', ->

      it 'should call callback with rows if operation returns some rows', ->
        data = [{},{}]
        sut.db = data

        sut.gather callback

        assert callback.calledWith null, data

      it 'should call callback with empty array if operation does not find item', ->
        sut.db = []

        sut.gather callback

        assert callback.calledWith null, []

    describe 'find', ->
      data =
        method: 'GET'

      it 'should call callback with null, row if operation returns a row', ->
        row = new Endpoint()
        sut.create {}
        sut.find data, callback

        assert callback.args[0][0] is null
        assert callback.args[0][1]

      it 'should call callback with error if operation does not find item', ->
        sut.find data, callback

        assert callback.calledWith "Endpoint with given request doesn't exist."

      it 'should call callback after timeout if data response has a latency', (done) ->
        sut.create
          request: {}
          response:
            latency: 1000

        sut.find data, callback

        waitsFor (-> callback.called), 'Callback call was never called', [900, 1100], done

      describe 'dynamic templating', ->
        it 'should replace all captures in body', (done) ->
          sut.create
            request:
              url: '/'
              post: '.*'
            response:
              body: 'you posted "<% post[0] %>" and "<% post[0] %>"'

          data =
            url: '/'
            method: 'GET'
            post: 'hello, there!'

          sut.find data, (err, match) ->
            assert match.body is 'you posted "hello, there!" and "hello, there!"'
            done()

        it 'should replace captures in a text file', ->
          expected = 'file contents!'
          sut.create
            request:
              url: '/'
              post: '.*'
            response:
              file: 'test/data/<% post[0] %>.file'

          data =
            url: '/'
            method: 'GET'
            post: 'endpoints'

          sut.find data, callback

          assert callback.args[0][1].body.toString().trim() is expected

        it 'should return binary data unmolested', ->
          expected = new Buffer([
            0x80, 0x81, 0x82, 0xab, 0xcd, 0xef, 0x3c, 0x25,
            0x20, 0x70, 0x6f, 0x73, 0x74, 0x5b, 0x30, 0x5d,
            0x20, 0x25, 0x3e, 0xfe, 0xdc, 0xba, 0x82, 0x81,
            0x80
          ])
          sut.create
            request:
              url: '/'
              post: '.*'
            response:
              file: 'test/data/<% post[0] %>.file'

          data =
            url: '/'
            method: 'GET'
            post: 'binary'

          sut.find data, callback

          body = callback.args[0][1].body
          assert (body instanceof Buffer) and bufferEqual(body, expected)

      describe 'request post versus file', ->
        it 'should match response with post if file is not supplied', ->
          expected = { status: 200 }
          sut.create
            request:
              url: '/testing'
              post: 'the post!'
              method: 'post'
            response: expected
          data =
            method: 'POST'
            url: '/testing'
            post: 'the post!'

          sut.find data, callback

          assert callback.calledWith null

        it 'should match response with post file is supplied but cannot be found', ->
          expected = { status : 200 }
          sut.create
            request:
              url: '/testing'
              file: 'test/data/endpoints-nonexistant.file'
              post: 'post data!'
              method: 'post'
            response: expected
          data =
            method: 'POST'
            url: '/testing'
            post: 'post data!'

          sut.find data, callback

          assert callback.calledWith null

        it 'should match response with file if file is supplied and exists', ->
          expected = { status : 200 }
          sut.create
            request:
              url: '/testing'
              file: 'test/data/endpoints.file'
              post: 'post data!'
              method: 'post'
            response: expected
          data =
            url: '/testing'
            post: 'file contents!'
            method: 'POST'

          sut.find data, callback

          assert callback.calledWith null

      describe 'response body versus file', ->
        it 'should return response with body as content if file is not supplied', ->
          expected = 'the body!'
          sut.create
            request:
              url: '/testing'
            response:
              body: expected
          data =
            url: '/testing'
            method: 'GET'

          sut.find data, callback

          assert callback.args[0][1].body.toString() is expected

        it 'should return response with body as content if file is supplied but cannot be found', ->
          expected = 'the body!'
          sut.create
            request:
              url: '/testing'
            response:
              body: expected
              file: 'test/data/endpoints-nonexistant.file'
          data =
            url: '/testing'
            method: 'GET'

          sut.find data, callback

          assert callback.args[0][1].body.toString() is expected

        it 'should return response with file as content if file is supplied and exists', ->
          expected = 'file contents!'
          sut.create
            request:
              url: '/testing'
            response:
              body: 'body contents!'
              file: 'test/data/endpoints.file'
          data =
            url: '/testing'
            method: 'GET'

          sut.find data, callback

          assert callback.args[0][1].body.toString().trim() is expected

      describe 'method', ->
        it 'should return response even if cases match', ->
          sut.create
            request:
              method: 'POST'
            response: {}
          data =
            method: 'POST'

          sut.find data, callback

          assert callback.args[0][1]

        it 'should return response even if cases do not match', ->
          sut.create
            request:
              method: 'post'
            response: {}
          data =
            method: 'POST'

          sut.find data, callback

          assert callback.args[0][1]

        it 'should return response if method matches any of the defined', ->
          sut.create
            request:
              method: ['post', 'put']
            response: {}
          data =
            method: 'POST'

          sut.find data, callback

          assert callback.args[0][1]

        it 'should call callback with error if none of the methods match', ->
          sut.create
            request:
              method: ['post', 'put']
            response: {}
          data =
            method: 'GET'

          sut.find data, callback

          assert callback.calledWith "Endpoint with given request doesn't exist."

      describe 'headers', ->

        it 'should return response if all headers of request match', ->
          sut.create
            request:
              headers:
                'content-type': 'application/json'
            response: {}
          data =
            method: 'GET'
            headers:
              'content-type': 'application/json'

          sut.find data, callback

          assert callback.args[0][1]

        it 'should call callback with error if all headers of request dont match', ->
          sut.create
            request:
              headers:
                'content-type': 'application/json'
            response: {}
          data =
            method: 'GET'
            headers:
              'authentication': 'Basic gibberish:password'

          sut.find data, callback

          assert callback.calledWith "Endpoint with given request doesn't exist."

      describe 'query', ->

        it 'should return response if all query of request match', ->
          sut.create
            request:
              query:
                'first': 'value1'
            response: {}
          data =
            method: 'GET'
            query:
              'first': 'value1'


          sut.find data, callback

          assert callback.args[0][1]

        it 'should call callback with error if all query of request dont match', ->
          sut.create
            request:
              query:
                'first': 'value1'
            response: {}
          data =
            method: 'GET'
            query:
              'unknown': 'good question'

          sut.find data, callback

          assert callback.calledWith "Endpoint with given request doesn't exist."
