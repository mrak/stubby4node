describe 'CLI', ->
   sut = null

   beforeEach ->
      sut = require('../src/cli')
      spyOn process, 'exit'
      spyOn sut, 'log'

   describe 'getLocation', ->
      it 'should return default if no flag provided', ->
         expected = 'localhost'
         actual = sut.getLocation []

         expect(actual).toBe expected

      it 'should return supplied value when provided', ->
         expected = 'stubby.com'
         actual = sut.getLocation ['-l', expected]

         expect(actual).toBe expected

      it 'should return supplied value when provided with full flag', ->
         expected = 'stubby.com'
         actual = sut.getLocation ['--location', expected]

         expect(actual).toBe expected

   describe 'version (-v)', ->
      it 'should exit the process if the second paramete is true', ->
         sut.version ['-v'], true

         expect(process.exit).toHaveBeenCalled()

      it 'should print out help text to console', ->
         sut.version ['-v'], true

         expect(sut.log).toHaveBeenCalled()

      it "shouldn't exit the process if second parameter is blank", ->
         sut.version ['-v']

         expect(process.exit).not.toHaveBeenCalled()

      it "shouldn't print to the console or exit if -h isn't supplied", ->
         sut.help []

         expect(process.exit).not.toHaveBeenCalled()
         expect(sut.log).not.toHaveBeenCalled()

   describe 'help (-h)', ->
      it 'should exit the process if second parameter is true', ->
         sut.help ['-h'], true

         expect(process.exit).toHaveBeenCalled()

      it 'should print out help text to console', ->
         sut.help ['-h'], true

         expect(sut.log).toHaveBeenCalled()

      it "shouldn't exit the process if second parameter is blank", ->
         sut.help ['-h']

         expect(process.exit).not.toHaveBeenCalled()

      it "shouldn't print to the console or exit if -h isn't supplied", ->
         sut.help []

         expect(process.exit).not.toHaveBeenCalled()
         expect(sut.log).not.toHaveBeenCalled()

   describe 'getData', ->
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
         actual = sut.getData ['-d', 'spec/data/cli.getData.json']

         expect(actual).toEqual expected

      it 'should be about to parse yaml file with array', ->
         actual = sut.getData ['-d', 'spec/data/cli.getData.yaml']

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

      it 'should return supplied value when provided with full flag', ->
         expected = 80
         actual = sut.getStub ['--stub', expected]

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

      it 'should return supplied value when provided with full flag', ->
         expected = 81
         actual = sut.getAdmin ['--admin', expected]

         expect(actual).toBe expected

   describe 'getKey', ->
      expected = 'some generated key'

      it 'should return null if no flag provided', ->
         actual = sut.getKey []

         expect(actual).toBeNull()

      it 'should return contents of file when flag provided', ->
         actual = sut.getKey ['-k', 'spec/data/cli.getKey.pem']

         expect(actual).toBe expected

   describe 'getCert', ->
      expected = 'some generated certificate'

      it 'should return null if no flag provided', ->
         actual = sut.getCert []

         expect(actual).toBeNull()

      it 'should return contents of file when flag provided', ->
         actual = sut.getCert ['-c', 'spec/data/cli.getCert.pem']

         expect(actual).toBe expected

   describe 'getPfx', ->
      expected = 'some generated pfx'

      it 'should return null if no flag provided', ->
         actual = sut.getPfx []

         expect(actual).toBeNull()

      it 'should return contents of file when flag provided', ->
         actual = sut.getPfx ['-p', 'spec/data/cli.getPfx.pfx']

         expect(actual).toBe expected


   describe 'getArgs', ->
      it 'should gather all arguments', ->
         expected = 
            data : 'a file'
            stub : 88
            admin : 90
            location : 'stubby.com'
            key: 'a key'
            cert: 'a certificate'
            pfx: 'a pfx'

         spyOn(sut, 'getData').andReturn expected.data
         spyOn(sut, 'getKey').andReturn expected.key
         spyOn(sut, 'getCert').andReturn expected.cert
         spyOn(sut, 'getPfx').andReturn expected.pfx

         actual = sut.getArgs [
            '-s', expected.stub,
            '-a', expected.admin,
            '-d', 'anything',
            '-l', expected.location
            '-k', 'anything'
            '-c', 'anything'
            '-p', 'anything'
         ]

         expect(actual).toEqual expected
