sinon = require 'sinon'
Admin = require('../src/portals/admin').Admin
require('../src/console/out').mute = true
assert = require 'assert'

describe 'Admin', ->
   response = null
   request = null
   sut = null
   endpoints = null

   beforeEach ->
      sinon.spy console, 'info'
      endpoints =
         create   : sinon.spy()
         retrieve : sinon.spy()
         update   : sinon.spy()
         delete   : sinon.spy()
         gather   : sinon.spy()
      sut = new Admin(endpoints, true)

      request =
         url: '/'
         method : 'POST'
         headers : {}
         on: sinon.spy()
      response =
         setHeader : sinon.spy()
         writeHead : sinon.spy()
         write : sinon.spy()
         end : sinon.spy()
         on : sinon.spy()

   afterEach ->
      console.info.restore()

   describe 'urlValid', ->
      it 'should accept the root url', ->
         url = '/'

         result = sut.urlValid url

         assert result

      it 'should not accept urls with a-z in them', ->
         url = '/abcdefhijklmnopqrstuvwxyz'

         result = sut.urlValid url

         assert not result

      it 'should accept urls of digits', ->
         url = '/1'

         result = sut.urlValid url

         assert result

      it 'should not accept urls not beginning in /', ->
         url = '123456'

         result = sut.urlValid url

         assert not result

      it 'should not accept urls beginning with 0', ->
         url = '/012'

         result = sut.urlValid url

         assert not result

   describe 'getId', ->
      it 'should get valid id from url', ->
         id = '123'
         url = "/#{id}"

         actual = sut.getId url

         assert actual is id

      it 'should return nothing for root url', ->
         url = "/"

         actual = sut.getId url

         assert not actual


   describe 'notSupported', ->
      it 'should status code with "405 Not Supported" code and end response', ->
         sut.notSupported response

         assert response.statusCode is 405
         assert response.end.calledOnce

   describe 'notFound', ->
      it 'should write header with "404 Not Found" code and end response', ->
         sut.notFound response

         assert response.writeHead.calledWith 404
         assert response.end.calledOnce

   describe 'serverError', ->
      it 'should write header with "500 Server Error" code and end response', ->
         sut.serverError response

         assert response.writeHead.calledWith 500
         assert response.end.calledOnce

   describe 'saveError', ->
      it 'should write header with "422 Uprocessable Entity" code and end response', ->
         sut.saveError response

         assert response.writeHead.calledWith 422
         assert response.end.calledOnce

   describe 'noContent', ->
      it 'should write header with "204 No Content" code and end response', ->
         sut.noContent response

         assert response.statusCode is 204
         assert response.end.calledOnce

   describe 'ok', ->
      it 'should write header with "200 OK" code and end response', ->
         sut.ok response

         assert response.writeHead.calledWith 200
         assert response.end.calledOnce

      it 'should write JSON content if supplied', ->
         content = {}

         sut.ok response, content

         assert response.end.calledOnce
         assert response.end.args[0].length is 1

      it 'should write nothing if content is null', ->
         content = null

         sut.ok response, content

         assert response.write.callCount is 0

      it 'should write nothing if content is undefined', ->
         sut.ok response

         assert response.write.callCount is 0

   describe 'created', ->
      id = null

      beforeEach ->
         request.headers.host = 'testHost'
         id = '42'

      it 'should write header with "201 Content Created" code and end response', ->
         sut.created response, request, id

         assert response.writeHead.calledWith 201
         assert response.end.calledOnce

      it 'should write header with Location set', ->
         expected = {'Location':"#{request.headers.host}/#{id}"}
         sut.created response, request, id

         assert.deepEqual response.writeHead.args[0][1], expected

   describe 'server', ->
      it 'should call notFound if url not valid', ->
         sinon.stub(sut, 'urlValid').returns false
         sinon.spy sut, 'notFound'

         sut.server request, response

         assert sut.notFound.calledOnce

      it 'should call goPOST if method is POST', ->
         sinon.stub(sut, 'urlValid').returns true
         request.method = 'POST'
         sinon.spy sut, 'goPOST'

         sut.server request, response

         assert sut.goPOST.calledOnce

      it 'should call goPUT if method is PUT', ->
         sinon.stub(sut, 'urlValid').returns true
         request.method = 'PUT'
         sinon.spy sut, 'goPUT'

         sut.server request, response

         assert sut.goPUT.calledOnce

      it 'should call goGET if method is GET', ->
         sinon.stub(sut, 'urlValid').returns true
         request.method = 'GET'
         sinon.spy sut, 'goGET'

         sut.server request, response

         assert sut.goGET.calledOnce

      it 'should call goDELETE if method is DELETE', ->
         sinon.stub(sut, 'urlValid').returns true
         request.method = 'DELETE'
         sinon.spy sut, 'goDELETE'

         sut.server request, response

         assert sut.goDELETE.calledOnce

   describe 'POST data handlers', ->
      contract = null

      beforeEach ->
         request.on = (event, callback) -> callback()
         sinon.stub(sut, 'contract').returns null

      describe 'goPUT', ->
         it 'should send not supported if there is no id in the url', ->
            sinon.stub(sut, 'getId').returns ''
            sinon.spy sut, 'notSupported'

            sut.goPUT request, response

            assert sut.notSupported.calledOnce

      describe 'processPUT', ->
         it 'should update item if data is JSON parsable', ->
            data = '{"property":"value"}'

            sut.processPUT "any id", data, response

            assert endpoints.update.calledOnce

         it 'should not update item if data isnt JSON parsable', ->
            data = "<H#rg"

            sut.processPUT "any id", data, response

            assert endpoints.update.callCount is 0

         it 'should return BAD REQUEST when contract is violated', ->
            data = '{"property":"value"}'
            sut.contract.returns []
            sinon.spy sut, 'badRequest'

            sut.processPUT "any id", data, response

            assert sut.badRequest.calledOnce
            assert sut.contract.calledOnce

      describe 'goPOST', ->
         it 'should send not supported if there is an id in the url', ->
            sinon.stub(sut, 'getId').returns '123'
            sinon.spy sut, 'notSupported'

            sut.goPOST request, response

            assert sut.notSupported.calledOnce

      describe 'processPOST', ->
         it 'should create item if data is JSON parsable', ->
            data = '{"property":"value"}'

            sut.processPOST data, response, request

            assert endpoints.create.calledOnce

         it 'should not create item if data isnt JSON parsable', ->
            data = "<H#rg"

            sut.processPOST data, response, request

            assert endpoints.create.callCount is 0

         it 'should return BAD REQUEST when contract is violated', ->
            data = '{"property":"value"}'
            sut.contract.returns []
            sinon.spy sut, 'badRequest'

            sut.processPOST data, response, request

            assert sut.badRequest.calledOnce
            assert sut.contract.calledOnce

      describe 'goDELETE', ->
         it 'should send not supported for the root url', ->
            sinon.stub(sut, 'getId').returns ''
            sinon.spy sut, 'notSupported'

            sut.goDELETE request, response

            assert sut.notSupported.calledOnce

         it 'should delete item if id was gathered', ->
            sinon.stub(sut, 'getId').returns '123'

            sut.goDELETE request, response

            assert endpoints.delete.calledOnce

      describe 'goGET', ->
         it 'should gather all for the root url', ->
            sinon.stub(sut, 'getId').returns ''

            sut.goGET request, response

            assert endpoints.gather.calledOnce

         it 'should retrieve item if id was gathered', ->
            sinon.stub(sut, 'getId').returns '123'

            sut.goGET request, response

            assert endpoints.retrieve.calledOnce
