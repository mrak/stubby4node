sut = null
CLI = require '../src/console/cli'
defaults = CLI.getArgs []
options = null

afterFn = ->

describe 'main', ->
   stopStubby = ->
      stopped = false
      sut.stop -> stopped = true
      waitsFor (-> stopped), 'stubby to stop', 1

   beforeEach ->
      if sut? then stopStubby()
      sut = new (require('../src/main').Stubby)()

   afterEach stopStubby

   describe 'start', ->
      beforeEach ->
         options = {}

      describe 'callback', ->
         it 'should treat the callback as optional', ->
            callback = jasmine.createSpy 'callback'
            sut.start {}, callback

            waitsFor (-> callback.callCount is 1), 'callback to have been called', 1

         it 'should take one parameter as a function', ->
            callback = jasmine.createSpy 'callback'
            sut.start callback

            waitsFor (-> callback.callCount is 1), 'callback to have been called', 1

      describe 'options', ->
         it 'should default stub port to CLI port default', ->
            go = false
            sut.start options, -> go = true

            waitsFor (-> go and options.stubs is defaults.stubs), 'option stub to be set', 1

         it 'should default admin port to CLI port default', ->
            go = false
            sut.start options, -> go = true

            waitsFor (-> go and options.admin is defaults.admin), 'option admin to be set', 1

         it 'should default location to CLI default', ->
            go = false
            sut.start options, -> go = true

            waitsFor (-> go and options.location is defaults.location), 'option location to be set', 1

         it 'should default data to empty array', ->
            go = false
            sut.start options, -> go = true

            waitsFor (-> go and options.data instanceof Array and options.data.length is 0), "option.data to be set to empty array #{options.data}", 1

         it 'should default key to null', ->
            go = false
            sut.start options, -> go = true

            waitsFor (-> go and options.key is defaults.key), 'option.key to be null', 1

         it 'should default cert to null', ->
            go = false
            sut.start options, -> go = true

            waitsFor (-> go and options.cert is defaults.cert), 'option.cert to be null', 1
