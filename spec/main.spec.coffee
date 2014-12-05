sut = null
CLI = require '../lib/console/cli'
defaults = CLI.getArgs []
options = null

sinon = require 'sinon'
waitsFor = require './helpers/waits-for'
assert = require 'assert'

describe 'main', ->
    sut = null
    stopStubby = (finish) ->
        if sut? then return sut.stop finish
        finish()

    beforeEach (done) ->
        finish = ->
            sut = new (require('../lib/main').Stubby)()
            done()

        stopStubby finish

    afterEach stopStubby

    describe 'put', ->
        it 'should return warning when the contract is violated', (done) ->
            callback = sinon.spy()
            sut.endpoints =
                update: (_,__,cb) -> cb(null)

            sut.put '42', {
                request:
                    url: '/somewhere'
                response:
                    status: 800
            }, callback

            waitsFor (-> callback.called), 'callback to have been called', 10, ->
                assert callback.args[0][0] is "The supplied endpoint data couldn't be saved"
                done()

        it 'should not return warning when the contract is upheld', (done) ->
            callback = sinon.spy()
            sut.endpoints =
                update: (_,__,cb) -> cb(null)

            sut.put '42', {
                request:
                    url: '/somewhere'
                response:
                    status: 200
            }, callback

            waitsFor (-> callback.called), 'callback to have been called', 10, ->
                assert callback.args[0][0] is null
                done()

    describe 'post', ->
        it 'should return warning when the contract is violated', (done) ->
            callback = sinon.spy()

            sut.post {
                request:
                    url: '/somewhere'
                response:
                    status: 800
            }, callback

            waitsFor (-> callback.called), 'callback to have been called', 10, ->
                assert callback.args[0][0] is "The supplied endpoint data couldn't be saved"
                done()

        it 'should not return warning when the contract is upheld', (done) ->
            callback = sinon.spy()

            sut.post {
                request:
                    url: '/somewhere'
                response:
                    status: 200
            }, callback

            waitsFor (-> callback.called), 'callback to have been called', 10, ->
                assert callback.args[0][0] is null
                done()

    describe 'start', ->
        beforeEach ->
            options = {}

        describe 'callback', ->
            it 'should treat the callback as optional', (done) ->
                callback = sinon.spy()
                sut.start {}, callback

                waitsFor (-> callback.called), 'callback to have been called', 10, done

            it 'should take one parameter as a function', (done) ->
                callback = sinon.spy()
                sut.start callback

                waitsFor (-> callback.called), 'callback to have been called', 10, done

        describe 'options', ->
            it 'should default stub port to CLI port default', (done) ->
                sut.start options, ->
                    assert options.stubs is defaults.stubs
                    done()

            it 'should default admin port to CLI port default', (done) ->
                sut.start options, ->
                    assert options.admin is defaults.admin
                    done()

            it 'should default location to CLI default', (done) ->
                sut.start options, ->
                    assert options.location is defaults.location
                    done()

            it 'should default data to empty array', (done) ->
                sut.start options, ->
                    assert options.data instanceof Array
                    assert options.data.length is 0
                    done()

            it 'should default key to null', (done) ->
                sut.start options, ->
                    assert options.key is defaults.key
                    done()

            it 'should default cert to null', (done) ->
                sut.start options, ->
                    assert options.cert is defaults.cert
                    done()
