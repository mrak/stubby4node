assert = require 'assert'

describe 'CLI', ->
   sut = null
   out = null

   beforeEach ->
      sut = require('../lib/console/cli')
      out = require '../lib/console/out'
      @sandbox.stub process, 'exit'
      @sandbox.stub out, 'log'

   afterEach ->
      process.exit.restore()
      out.log.restore()

   describe 'version', ->
      it 'should return the version of stubby in package.json', ->
         expected = require('../package.json').version

         sut.version true

         assert out.log.calledWith expected

   describe 'help', ->
      it 'should return help text', ->
         sut.help true

         assert out.log.calledOnce

   describe 'getArgs', ->
      describe '-a, --admin', ->
         it 'should return default if no flag provided', ->
            expected = 8889
            actual = sut.getArgs []

            assert actual.admin is expected

         it 'should return supplied value when provided', ->
            expected = "81"
            actual = sut.getArgs ['-a', expected]

            assert actual.admin is expected

         it 'should return supplied value when provided with full flag', ->
            expected = "81"
            actual = sut.getArgs ['--admin', expected]

            assert actual.admin is expected

      describe '-s, --stubs', ->
         it 'should return default if no flag provided', ->
            expected = 8882
            actual = sut.getArgs []

            assert actual.stubs is expected

         it 'should return supplied value when provided', ->
            expected = "80"
            actual = sut.getArgs ['-s', expected]

            assert actual.stubs is expected

         it 'should return supplied value when provided with full flag', ->
            expected = "80"
            actual = sut.getArgs ['--stubs', expected]

            assert actual.stubs is expected

      describe '-t, --tls', ->
         it 'should return default if no flag provided', ->
            expected = 7443
            actual = sut.getArgs []

            assert actual.tls is expected

         it 'should return supplied value when provided', ->
            expected = "443"
            actual = sut.getArgs ['-t', expected]

            assert actual.tls is expected

         it 'should return supplied value when provided with full flag', ->
            expected = "443"
            actual = sut.getArgs ['--tls', expected]

            assert actual.tls is expected

      describe '-l, --location', ->
         it 'should return default if no flag provided', ->
            expected = '0.0.0.0'
            actual = sut.getArgs []

            assert actual.location is expected

         it 'should return supplied value when provided', ->
            expected = 'stubby.com'
            actual = sut.getArgs ['-l', expected]

            assert actual.location is expected

         it 'should return supplied value when provided with full flag', ->
            expected = 'stubby.com'
            actual = sut.getArgs ['--location', expected]

            assert actual.location is expected

      describe '-v, --version', ->
         it 'should exit the process', ->
            sut.getArgs(['--version'])

            assert process.exit.calledOnce

         it 'should print out version info', ->
            version = require('../package.json').version

            sut.getArgs(['-v'])

            assert out.log.calledWith version

      describe '-h, --help', ->
         it 'should exit the process', ->
            sut.getArgs(['--help'])

            assert process.exit.calledOnce

         it 'should print out help text', ->
            help = sut.help()

            sut.getArgs(['-h'])

            assert out.log.calledOnce

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

         assert.deepEqual actual.data, expected

      it 'should be about to parse yaml file with array', ->
         actual = sut.getArgs ['-d', 'spec/data/cli.getData.yaml']

         assert.deepEqual actual.data, expected

   describe 'key', ->
      it 'should return contents of file', ->
         expected = 'some generated key'
         actual = sut.key 'spec/data/cli.getKey.pem'

         assert actual is expected

   describe 'cert', ->
      expected = 'some generated certificate'

      it 'should return contents of file', ->
         actual = sut.cert 'spec/data/cli.getCert.pem'

         assert actual is expected

   describe 'pfx', ->
      it 'should return contents of file', ->
         expected = 'some generated pfx'
         actual = sut.pfx 'spec/data/cli.getPfx.pfx'

         assert actual is expected

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
            datadir: process.cwd()
            help: undefined
            version: (require '../package.json').version

         @sandbox.stub(sut, 'data').returns expected.data
         @sandbox.stub(sut, 'key').returns expected.key
         @sandbox.stub(sut, 'cert').returns expected.cert
         @sandbox.stub(sut, 'pfx').returns expected.pfx

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

         assert.deepEqual actual, expected

         sut.data.restore()
         sut.key.restore()
         sut.cert.restore()
         sut.pfx.restore()
