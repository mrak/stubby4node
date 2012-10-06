Admin = require('../src/portals/admin').Admin

describe 'Admin', ->
   response = null
   request = null
   sut = null
   endpoints = null

   beforeEach ->
      spyOn console, 'info'
      endpoints =
         create   : jasmine.createSpy 'endpoints.create'
         retrieve : jasmine.createSpy 'endpoints.retrieve'
         update   : jasmine.createSpy 'endpoints.update'
         delete   : jasmine.createSpy 'endpoints.delete'
         gather   : jasmine.createSpy 'endpoints.gather'
      sut = new Admin(endpoints, true)

      request =
         url: '/'
         method : 'POST'
         headers : {}
      response =
         setHeader : jasmine.createSpy()
         writeHead : jasmine.createSpy()
         write : jasmine.createSpy()
         end : jasmine.createSpy()

   describe 'urlValid', ->
      it 'should accept the root url', ->
         url = '/'

         result = sut.urlValid url

         expect(result).toBeTruthy()

      it 'should not accept urls with a-z in them', ->
         url = '/abcdefhijklmnopqrstuvwxyz'

         result = sut.urlValid url

         expect(result).toBeFalsy()

      it 'should accept urls of digits', ->
         url = '/1'

         result = sut.urlValid url

         expect(result).toBeTruthy()

      it 'should not accept urls not beginning in /', ->
         url = '123456'

         result = sut.urlValid url

         expect(result).toBeFalsy()

      it 'should not accept urls beginning with 0', ->
         url = '/012'

         result = sut.urlValid url

         expect(result).toBeFalsy()

   describe 'getId', ->
      it 'should get valid id from url', ->
         id = '123'
         url = "/#{id}"

         actual = sut.getId url

         expect(actual).toBe id

      it 'should return nothing for root url', ->
         url = "/"

         actual = sut.getId url

         expect(actual).toBeFalsy()


   describe 'notSupported', ->
      it 'should status code with "405 Not Supported" code and end response', ->
         sut.notSupported response

         expect(response.statusCode).toBe 405
         expect(response.end).toHaveBeenCalled()

   describe 'notFound', ->
      it 'should write header with "404 Not Found" code and end response', ->
         sut.notFound response

         expect(response.writeHead.mostRecentCall.args[0]).toBe 404
         expect(response.end).toHaveBeenCalled()

   describe 'serverError', ->
      it 'should write header with "500 Server Error" code and end response', ->
         sut.serverError response

         expect(response.writeHead.mostRecentCall.args[0]).toBe 500
         expect(response.end).toHaveBeenCalled()

   describe 'saveError', ->
      it 'should write header with "422 Uprocessable Entity" code and end response', ->
         sut.saveError response

         expect(response.writeHead.mostRecentCall.args[0]).toBe 422
         expect(response.end).toHaveBeenCalled()

   describe 'noContent', ->
      it 'should write header with "204 No Content" code and end response', ->
         sut.noContent response

         expect(response.statusCode).toBe 204
         expect(response.end).toHaveBeenCalled()

   describe 'ok', ->
      it 'should write header with "200 OK" code and end response', ->
         sut.ok response

         expect(response.writeHead.mostRecentCall.args[0]).toBe 200
         expect(response.end).toHaveBeenCalled()

      it 'should write JSON content if supplied', ->
         content = {}

         sut.ok response, content

         expect(response.write).toHaveBeenCalled()

      it 'should write nothing if content is null', ->
         content = null

         sut.ok response, content

         expect(response.write).not.toHaveBeenCalled()

      it 'should write nothing if content is undefined', ->
         sut.ok response

         expect(response.write).not.toHaveBeenCalled()

   describe 'created', ->
      id = null

      beforeEach ->
         request.headers.host = 'testHost'
         id = '42'

      it 'should write header with "201 Content Created" code and end response', ->
         sut.created response, request, id

         expect(response.writeHead.mostRecentCall.args[0]).toBe 201
         expect(response.end).toHaveBeenCalled()

      it 'should write header with Location set', ->
         expected = {'Location':"#{request.headers.host}/#{id}"}
         sut.created response, request, id

         expect(response.writeHead.mostRecentCall.args[1]).toEqual expected

   describe 'server', ->
      it 'should call notFound if url not valid', ->
         spyOn(sut, 'urlValid').andReturn false
         spyOn sut, 'notFound'

         sut.server request, response

         expect(sut.notFound).toHaveBeenCalled()

      it 'should call goPOST if method is POST', ->
         spyOn(sut, 'urlValid').andReturn true
         request.method = 'POST'
         spyOn sut, 'goPOST'

         sut.server request, response

         expect(sut.goPOST).toHaveBeenCalled()

      it 'should call goPUT if method is PUT', ->
         spyOn(sut, 'urlValid').andReturn true
         request.method = 'PUT'
         spyOn sut, 'goPUT'

         sut.server request, response

         expect(sut.goPUT).toHaveBeenCalled()

      it 'should call goGET if method is GET', ->
         spyOn(sut, 'urlValid').andReturn true
         request.method = 'GET'
         spyOn sut, 'goGET'

         sut.server request, response

         expect(sut.goGET).toHaveBeenCalled()

      it 'should call goDELETE if method is DELETE', ->
         spyOn(sut, 'urlValid').andReturn true
         request.method = 'DELETE'
         spyOn sut, 'goDELETE'

         sut.server request, response

         expect(sut.goDELETE).toHaveBeenCalled()

   describe 'POST data handlers', ->
      contract = null

      beforeEach ->
         request.on = (event, callback) -> callback()
         spyOn(sut, 'contract').andReturn null

      describe 'goPUT', ->
         it 'should send not supported if there is no id in the url', ->
            spyOn(sut, 'getId').andReturn ''
            spyOn sut, 'notSupported'

            sut.goPUT request, response

            expect(sut.notSupported).toHaveBeenCalled()

      describe 'processPUT', ->
         it 'should update item if data is JSON parsable', ->
            data = '{"property":"value"}'

            sut.processPUT "any id", data, response

            expect(endpoints.update).toHaveBeenCalled()

         it 'should not update item if data isnt JSON parsable', ->
            data = "<H#rg"

            sut.processPUT "any id", data, response

            expect(endpoints.update).not.toHaveBeenCalled()

         it 'should return BAD REQUEST when contract is violated', ->
            data = '{"property":"value"}'
            sut.contract.andReturn []
            spyOn sut, 'badRequest'

            sut.processPUT "any id", data, response

            expect(sut.badRequest).toHaveBeenCalled()
            expect(sut.contract).toHaveBeenCalled()

      describe 'goPOST', ->
         it 'should send not supported if there is an id in the url', ->
            spyOn(sut, 'getId').andReturn '123'
            spyOn sut, 'notSupported'

            sut.goPOST request, response

            expect(sut.notSupported).toHaveBeenCalled()

      describe 'processPOST', ->
         it 'should create item if data is JSON parsable', ->
            data = '{"property":"value"}'

            sut.processPOST data, response, request

            expect(endpoints.create).toHaveBeenCalled()

         it 'should not create item if data isnt JSON parsable', ->
            data = "<H#rg"

            sut.processPOST data, response, request

            expect(endpoints.create).not.toHaveBeenCalled()

         it 'should return BAD REQUEST when contract is violated', ->
            data = '{"property":"value"}'
            sut.contract.andReturn []
            spyOn sut, 'badRequest'

            sut.processPOST data, response, request

            expect(sut.badRequest).toHaveBeenCalled()
            expect(sut.contract).toHaveBeenCalled()

      describe 'goDELETE', ->
         it 'should send not supported for the root url', ->
            spyOn(sut, 'getId').andReturn ''
            spyOn sut, 'notSupported'

            sut.goDELETE request, response

            expect(sut.notSupported).toHaveBeenCalled()

         it 'should delete item if id was gathered', ->
            spyOn(sut, 'getId').andReturn '123'

            sut.goDELETE request, response

            expect(endpoints.delete).toHaveBeenCalled()

      describe 'goGET', ->
         it 'should gather all for the root url', ->
            spyOn(sut, 'getId').andReturn ''

            sut.goGET request, response

            expect(endpoints.gather).toHaveBeenCalled()

         it 'should retrieve item if id was gathered', ->
            spyOn(sut, 'getId').andReturn '123'

            sut.goGET request, response

            expect(endpoints.retrieve).toHaveBeenCalled()
