describe 'CLI', ->
   sut = null
   out = null

   beforeEach ->
      sut = require('../src/console/cli')
      out = require '../src/console/out'
      spyOn process, 'exit'
      spyOn out, 'log'

   describe 'version', ->
      it 'should return the version of stubby in package.json', ->
         expected = require('../package.json').version

         sut.version true

         expect(out.log).toHaveBeenCalledWith expected

   describe 'help', ->
      it 'should return help text', ->
         sut.help true

         expect(out.log).toHaveBeenCalled()

   describe 'getArgs', ->
      describe '-a, --admin', ->
         it 'should return default if no flag provided', ->
            expected = 8889
            actual = sut.getArgs []

            expect(actual.admin).toBe expected

         it 'should return supplied value when provided', ->
            expected = "81"
            actual = sut.getArgs ['-a', expected]

            expect(actual.admin).toBe expected

         it 'should return supplied value when provided with full flag', ->
            expected = "81"
            actual = sut.getArgs ['--admin', expected]

            expect(actual.admin).toBe expected

      describe '-s, --stubs', ->
         it 'should return default if no flag provided', ->
            expected = 8882
            actual = sut.getArgs []

            expect(actual.stubs).toBe expected

         it 'should return supplied value when provided', ->
            expected = "80"
            actual = sut.getArgs ['-s', expected]

            expect(actual.stubs).toBe expected

         it 'should return supplied value when provided with full flag', ->
            expected = "80"
            actual = sut.getArgs ['--stubs', expected]

            expect(actual.stubs).toBe expected

      describe '-t, --tls', ->
         it 'should return default if no flag provided', ->
            expected = 7443
            actual = sut.getArgs []

            expect(actual.tls).toBe expected

         it 'should return supplied value when provided', ->
            expected = "443"
            actual = sut.getArgs ['-t', expected]

            expect(actual.tls).toBe expected

         it 'should return supplied value when provided with full flag', ->
            expected = "443"
            actual = sut.getArgs ['--tls', expected]

            expect(actual.tls).toBe expected

      describe '-l, --location', ->
         it 'should return default if no flag provided', ->
            expected = 'localhost'
            actual = sut.getArgs []

            expect(actual.location).toBe expected

         it 'should return supplied value when provided', ->
            expected = 'stubby.com'
            actual = sut.getArgs ['-l', expected]

            expect(actual.location).toBe expected

         it 'should return supplied value when provided with full flag', ->
            expected = 'stubby.com'
            actual = sut.getArgs ['--location', expected]

            expect(actual.location).toBe expected
      describe '-v, --version', ->
         it 'should exit the process', ->
            sut.getArgs(['--version'])
            expect(process.exit).toHaveBeenCalled()

         it 'should print out version info', ->
            version = require('../package.json').version

            sut.getArgs(['-v'])

            expect(out.log).toHaveBeenCalledWith version

      describe '-h, --help', ->
         it 'should exit the process', ->
            sut.getArgs(['--help'])
            expect(process.exit).toHaveBeenCalled()

         it 'should print out help text', ->
            help = sut.help()

            sut.getArgs(['-h'])

            expect(out.log).toHaveBeenCalled()

   describe 'data', ->
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
         actual = sut.getArgs ['-d', 'spec/data/cli.getData.json']

         expect(actual.data).toEqual expected

      it 'should be about to parse yaml file with array', ->
         actual = sut.getArgs ['-d', 'spec/data/cli.getData.yaml']

         expect(actual.data).toEqual expected

   describe 'key', ->
      it 'should return contents of file', ->
         expected = 'some generated key'
         actual = sut.key 'spec/data/cli.getKey.pem'

         expect(actual).toBe expected

   describe 'cert', ->
      expected = 'some generated certificate'

      it 'should return contents of file', ->
         actual = sut.cert 'spec/data/cli.getCert.pem'

         expect(actual).toBe expected

   describe 'pfx', ->
      it 'should return contents of file', ->
         expected = 'some generated pfx'
         actual = sut.pfx 'spec/data/cli.getPfx.pfx'

         expect(actual).toBe expected

   describe 'getArgs', ->
      it 'should gather all arguments', ->
         filename = 'file.txt'
         expected = 
            data : 'a file'
            stubs : "88"
            admin : "90"
            location : 'stubby.com'
            key: 'a key'
            cert: 'a certificate'
            pfx: 'a pfx'
            tls: "443"
            mute: true
            watch: filename

         spyOn(sut, 'data').andReturn expected.data
         spyOn(sut, 'key').andReturn expected.key
         spyOn(sut, 'cert').andReturn expected.cert
         spyOn(sut, 'pfx').andReturn expected.pfx

         actual = sut.getArgs [
            '-s', expected.stubs
            '-a', expected.admin
            '-d', filename
            '-l', expected.location
            '-k', 'mocked'
            '-c', 'mocked'
            '-p', 'mocked'
            '-t', expected.tls
            '-m'
            '-w'
         ]

         expect(actual).toEqual expected
