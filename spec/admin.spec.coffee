Admin = require('../coffee/servers/admin').Admin

describe 'Admin', () ->
   response = {}
   request = {}
   sut = {}

   beforeEach () ->
      sut = Admin()

      request =
         url: '/'
         method : 'POST'
         headers : {}
      response =
         writeHead : jasmine.createSpy()
         write : jasmine.createSpy()
         end : jasmine.createSpy()

   describe 'urlValid', () ->

      it 'should accept the root url', () ->
         url = '/'

         result = sut.urlValid url

         expect(result).toBeTruthy()

      it 'should accept urls with a-f in them', () ->
         url = '/abcdef'

         result = sut.urlValid url

         expect(result).toBeTruthy()

      it 'should accept urls of digits', () ->
         url = '/1234567890'

         result = sut.urlValid url

         expect(result).toBeTruthy()

      it 'should not accept the urls with letters over f (hex)', () ->
         url = '/g'

         result = sut.urlValid url

         expect(result).toBeFalsy()

      it 'should not accept urls not beginning in /', () ->
         url = 'abcdef'

         result = sut.urlValid url

         expect(result).toBeFalsy()

   describe 'sendNotSupported', () ->
      it 'should write header with "405 Not Supported" code', () ->
         sut.sendNotSupported response
         expect(response.writeHead.mostRecentCall.args[0]).toBe 405

      it 'should end response', () ->
         sut.sendNotSupported response
         expect(response.end).toHaveBeenCalled()

   describe 'sendNotFound', () ->
      it 'should write header with "404 Not Found" code', () ->
         sut.sendNotFound response
         expect(response.writeHead.mostRecentCall.args[0]).toBe 404

      it 'should end response', () ->
         sut.sendNotFound response
         expect(response.end).toHaveBeenCalled()

   describe 'server', () ->
      it 'should call sendNotFound if url not valid', () ->
         spyOn(sut, 'urlValid').andReturn false
         spyOn sut, 'sendNotFound'

         sut.server request, response

         expect(sut.urlValid).toHaveBeenCalled()
         expect(sut.sendNotFound).toHaveBeenCalled()

      it 'should call goPOST if method is POST', () ->
         spyOn(sut, 'urlValid').andReturn true
         request.method = 'POST'
         spyOn sut, 'goPOST'

         sut.server request, response

         expect(sut.urlValid).toHaveBeenCalled()
         expect(sut.goPOST).toHaveBeenCalled()

      it 'should call goPUT if method is PUT', () ->
         spyOn(sut, 'urlValid').andReturn true
         request.method = 'PUT'
         spyOn sut, 'goPUT'

         sut.server request, response

         expect(sut.urlValid).toHaveBeenCalled()
         expect(sut.goPUT).toHaveBeenCalled()

      it 'should call goGET if method is GET', () ->
         spyOn(sut, 'urlValid').andReturn true
         request.method = 'GET'
         spyOn sut, 'goGET'

         sut.server request, response

         expect(sut.urlValid).toHaveBeenCalled()
         expect(sut.goGET).toHaveBeenCalled()

      it 'should call goDELETE if method is DELETE', () ->
         spyOn(sut, 'urlValid').andReturn true
         request.method = 'DELETE'
         spyOn sut, 'goDELETE'

         sut.server request, response

         expect(sut.urlValid).toHaveBeenCalled()
         expect(sut.goDELETE).toHaveBeenCalled()
