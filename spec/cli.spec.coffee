describe 'CLI', ->
   sut = null

   beforeEach ->
      sut = require('../src/cli').CLI
      spyOn process, 'exit'
      spyOn console, 'log'

   describe 'help (-h)', ->
      it 'should exit the process if second parameter is true', ->
         sut.help ['-h'], true

         expect(process.exit).toHaveBeenCalled()

      it 'should print out help text to console', ->
         sut.help ['-h'], true

         expect(console.log).toHaveBeenCalled()

      it "shouldn't exit the process if second parameter is blank", ->
         sut.help ['-h']

         expect(process.exit).not.toHaveBeenCalled()

      it "shouldn't print to the console or exit if -h isn't supplied", ->
         sut.help []

         expect(process.exit).not.toHaveBeenCalled()
         expect(console.log).not.toHaveBeenCalled()

   describe 'getFile', ->
      expected = [
         request:
            url: '/testput'
            method: 'PUT'
            post: 'test data'
         response:
            headers:
               'content-type': 'text/plain'
            status: 404
            latency: 2000
            body: 'test response'
      ,
         request:
            url: '/testdelete'
            method: 'DELETE'
            post: null
         response:
            headers:
               'content-type': 'text/plain'
            status: 204
            body: null
      ]

      it 'should be about to parse json file with array', ->
         actual = sut.getFile ['-f', 'spec/data/cli.getFile.json']

         expect(actual).toEqual expected

      it 'should be about to parse yaml file with array', ->
         actual = sut.getFile ['-f', 'spec/data/cli.getFile.yaml']

         expect(actual).toEqual expected

   describe 'getStub', ->
      it 'should return default if no flag provided', ->
         expected = 8882
         actual = sut.getStub []

         expect(actual).toBe expected

      it 'should return supplied value when provided', ->
         expected = 80
         actual = sut.getStub ['-s', expected]

         expect(actual).toBe expected

   describe 'getAdmin', ->
      it 'should return default if no flag provided', ->
         expected = 8889
         actual = sut.getAdmin []

         expect(actual).toBe expected

      it 'should return supplied value when provided', ->
         expected = 81
         actual = sut.getAdmin ['-a', expected]

         expect(actual).toBe expected

   describe 'getArgs', ->
      it 'should gather all arguments', ->
         expected = 
            file : 'a file'
            stub : 88
            admin : 90

         spyOn(sut, 'getFile').andReturn expected.file

         actual = sut.getArgs ['-s', expected.stub, '-a', expected.admin, '-f', 'dummy']

         expect(actual).toEqual expected
