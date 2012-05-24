Admin = require('../coffee/servers/admin').Admin

describe 'Admin', ->
   response = null
   request = null
   sut = null
   rNr = null

   beforeEach ->
      rNr =
         create   : jasmine.createSpy 'rNr.create'
         retrieve : jasmine.createSpy 'rNr.retrieve'
         update   : jasmine.createSpy 'rNr.update'
         delete   : jasmine.createSpy 'rNr.delete'
         gather   : jasmine.createSpy 'rNr.gather'
      sut = new Admin(rNr)

      request =
         url: '/'
         method : 'POST'
         headers : {}
      response =
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


   describe 'send.notSupported', ->
      it 'should write header with "405 Not Supported" code and end response', ->
         sut.send.notSupported response

         expect(response.writeHead.mostRecentCall.args[0]).toBe 405
         expect(response.end).toHaveBeenCalled()

   describe 'send.notFound', ->
      it 'should write header with "404 Not Found" code and end response', ->
         sut.send.notFound response

         expect(response.writeHead.mostRecentCall.args[0]).toBe 404
         expect(response.end).toHaveBeenCalled()

   describe 'send.serverError', ->
      it 'should write header with "500 Server Error" code and end response', ->
         sut.send.serverError response

         expect(response.writeHead.mostRecentCall.args[0]).toBe 500
         expect(response.end).toHaveBeenCalled()

   describe 'send.saveError', ->
      it 'should write header with "422 Uprocessable Entity" code and end response', ->
         sut.send.saveError response

         expect(response.writeHead.mostRecentCall.args[0]).toBe 422
         expect(response.end).toHaveBeenCalled()

   describe 'send.noContent', ->
      it 'should write header with "204 No Content" code and end response', ->
         sut.send.noContent response

         expect(response.writeHead.mostRecentCall.args[0]).toBe 204
         expect(response.end).toHaveBeenCalled()

   describe 'send.ok', ->
      it 'should write header with "200 OK" code and end response', ->
         sut.send.ok response

         expect(response.writeHead.mostRecentCall.args[0]).toBe 200
         expect(response.end).toHaveBeenCalled()

      it 'should write JSON content if supplied', ->
         content = {}

         sut.send.ok response, content

         expect(response.write).toHaveBeenCalled()

   describe 'send.created', ->
      id = null

      beforeEach ->
         request.headers.host = 'testHost'
         id = '42'

      it 'should write header with "201 Content Created" code and end response', ->
         sut.send.created response, request, id

         expect(response.writeHead.mostRecentCall.args[0]).toBe 201
         expect(response.end).toHaveBeenCalled()

      it 'should write header with Content-Location set', ->
         expected = {'Content-Location':"#{request.headers.host}/#{id}"}
         sut.send.created response, request, id

         expect(response.writeHead.mostRecentCall.args[1]).toEqual expected

   describe 'server', ->
      it 'should call send.notFound if url not valid', ->
         spyOn(sut, 'urlValid').andReturn false
         spyOn sut.send, 'notFound'

         sut.server request, response

         expect(sut.send.notFound).toHaveBeenCalled()

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
      beforeEach ->
         request.on = (event, callback) -> callback()

      describe 'goPUT', ->
         it 'should send not supported if there is no id in the url', ->
            spyOn(sut, 'getId').andReturn ''
            spyOn sut.send, 'notSupported'

            sut.goPUT request, response

            expect(sut.send.notSupported).toHaveBeenCalled()

         it 'should update item if id was gathered from url', ->
            spyOn(sut, 'getId').andReturn 'anything'

            sut.goPUT request, response

            expect(rNr.update).toHaveBeenCalled()

      describe 'goPOST', ->
         it 'should send not supported if there is an id in the url', ->
            spyOn(sut, 'getId').andReturn '123'
            spyOn sut.send, 'notSupported'

            sut.goPOST request, response

            expect(sut.send.notSupported).toHaveBeenCalled()

         it 'should create item if no id was gathered', ->
            spyOn(sut, 'getId').andReturn ''

            sut.goPOST request, response

            expect(rNr.create).toHaveBeenCalled()

      describe 'goDELETE', ->
         it 'should send not supported for the root url', ->
            spyOn(sut, 'getId').andReturn ''
            spyOn sut.send, 'notSupported'

            sut.goDELETE request, response

            expect(sut.send.notSupported).toHaveBeenCalled()

         it 'should delete item if id was gathered', ->
            spyOn(sut, 'getId').andReturn '123'

            sut.goDELETE request, response

            expect(rNr.delete).toHaveBeenCalled()

      describe 'goGET', ->
         it 'should gather all for the root url', ->
            spyOn(sut, 'getId').andReturn ''

            sut.goGET request, response

            expect(rNr.gather).toHaveBeenCalled()

         it 'should retrieve item if id was gathered', ->
            spyOn(sut, 'getId').andReturn '123'

            sut.goGET request, response

            expect(rNr.retrieve).toHaveBeenCalled()
