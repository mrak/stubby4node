#sut = null
#CLI = require '../src/console/cli'
#options = null

#afterFn = ->

#describe 'main', ->
   #beforeEach ->
      #sut = new (require('../src/main').Stubby)()

   #afterEach ->
      #stopped = false
      #sut.stop -> stopped = true
      #waitsFor (-> stopped), 'stubby to stop', 1

   #describe 'start', ->
      #beforeEach ->
         #options = {}

      #describe 'callback', ->
         #it 'should treat the callback as optional', ->
            #callback = jasmine.createSpy 'callback'
            #sut.start {}, callback

            #waitsFor (-> callback.callCount is 1), 'callback to have been called', 1

         #it 'should take one parameter as a function', ->
            #callback = jasmine.createSpy 'callback'
            #sut.start callback

            #waitsFor (-> callback.callCount is 1), 'callback to have been called', 1

      #describe 'options', ->
         #it 'should default stub port to CLI port default', ->
            #go = false
            #sut.start options, -> go = true

            #waitsFor (-> go and options.stubs is CLI.defaults.stubs), 'option stub to be set', 1

         #it 'should default admin port to CLI port default', ->
            #go = false
            #sut.start options, -> go = true

            #waitsFor (-> go and options.admin is CLI.defaults.admin), 'option admin to be set', 1

         #it 'should default location to CLI default', ->
            #go = false
            #sut.start options, -> go = true

            #waitsFor (-> go and options.location is CLI.defaults.location), 'option location to be set', 1

         #it 'should default data to empty array', ->
            #go = false
            #sut.start options, -> go = true

            #waitsFor (-> go and options.data isnt undefined), "option.data to be set to empty array #{options.data}", 1

         #it 'should default key to null', ->
            #go = false
            #sut.start options, -> go = true

            #waitsFor (-> go and options.key is null), 'option.key to be null', 1

         #it 'should default cert to null', ->
            #go = false
            #sut.start options, -> go = true

            #waitsFor (-> go and options.cert is null), 'option.cert to be null', 1
