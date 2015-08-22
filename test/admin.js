'use strict';

var Admin = require('../src/portals/admin').Admin;
var assert = require('assert');

require('../src/console/out').mute = true;

describe('Admin', function () {
  var endpoints, request, response, sut;
  response = null;
  request = null;
  sut = null;
  endpoints = null;
  beforeEach(function () {
    this.sandbox.spy(console, 'info');
    endpoints = {
      create: this.sandbox.spy(),
      retrieve: this.sandbox.spy(),
      update: this.sandbox.spy(),
      delete: this.sandbox.spy(),
      gather: this.sandbox.spy()
    };
    sut = new Admin(endpoints, true);
    request = {
      url: '/',
      method: 'POST',
      headers: {},
      on: this.sandbox.spy()
    };
    response = {
      setHeader: this.sandbox.spy(),
      writeHead: this.sandbox.spy(),
      write: this.sandbox.spy(),
      end: this.sandbox.spy(),
      on: this.sandbox.spy()
    };
  });
  describe('urlValid', function () {
    it('should accept the root url', function () {
      var result, url;
      url = '/';
      result = sut.urlValid(url);
      return assert(result);
    });
    it('should not accept urls with a-z in them', function () {
      var result, url;
      url = '/abcdefhijklmnopqrstuvwxyz';
      result = sut.urlValid(url);
      return assert(!result);
    });
    it('should accept urls of digits', function () {
      var result, url;
      url = '/1';
      result = sut.urlValid(url);
      return assert(result);
    });
    it('should not accept urls not beginning in /', function () {
      var result, url;
      url = '123456';
      result = sut.urlValid(url);
      return assert(!result);
    });
    return it('should not accept urls beginning with 0', function () {
      var result, url;
      url = '/012';
      result = sut.urlValid(url);
      return assert(!result);
    });
  });
  describe('getId', function () {
    it('should get valid id from url', function () {
      var actual, id, url;
      id = '123';
      url = '/' + id;
      actual = sut.getId(url);
      return assert(actual === id);
    });
    return it('should return nothing for root url', function () {
      var actual, url;
      url = '/';
      actual = sut.getId(url);
      return assert(!actual);
    });
  });
  describe('notSupported', function () {
    return it('should status code with "405 Not Supported" code and end response', function () {
      sut.notSupported(response);
      assert(response.statusCode === 405);
      return assert(response.end.calledOnce);
    });
  });
  describe('notFound', function () {
    return it('should write header with "404 Not Found" code and end response', function () {
      sut.notFound(response);
      assert(response.writeHead.calledWith(404));
      return assert(response.end.calledOnce);
    });
  });
  describe('serverError', function () {
    return it('should write header with "500 Server Error" code and end response', function () {
      sut.serverError(response);
      assert(response.writeHead.calledWith(500));
      return assert(response.end.calledOnce);
    });
  });
  describe('saveError', function () {
    return it('should write header with "422 Uprocessable Entity" code and end response', function () {
      sut.saveError(response);
      assert(response.writeHead.calledWith(422));
      return assert(response.end.calledOnce);
    });
  });
  describe('noContent', function () {
    return it('should write header with "204 No Content" code and end response', function () {
      sut.noContent(response);
      assert(response.statusCode === 204);
      return assert(response.end.calledOnce);
    });
  });
  describe('ok', function () {
    it('should write header with "200 OK" code and end response', function () {
      sut.ok(response);
      assert(response.writeHead.calledWith(200));
      return assert(response.end.calledOnce);
    });
    it('should write JSON content if supplied', function () {
      var content;
      content = {};
      sut.ok(response, content);
      assert(response.end.calledOnce);
      return assert(response.end.args[0].length === 1);
    });
    it('should write nothing if content is null', function () {
      var content;
      content = null;
      sut.ok(response, content);
      return assert(response.write.callCount === 0);
    });
    return it('should write nothing if content is undefined', function () {
      sut.ok(response);
      return assert(response.write.callCount === 0);
    });
  });
  describe('created', function () {
    var id;
    id = null;
    beforeEach(function () {
      request.headers.host = 'testHost';
      id = '42';
    });
    it('should write header with "201 Content Created" code and end response', function () {
      sut.created(response, request, id);
      assert(response.writeHead.calledWith(201));
      return assert(response.end.calledOnce);
    });
    return it('should write header with Location set', function () {
      var expected;
      expected = {
        Location: request.headers.host + '/' + id
      };
      sut.created(response, request, id);
      return assert.deepEqual(response.writeHead.args[0][1], expected);
    });
  });
  describe('server', function () {
    it('should call notFound if url not valid', function () {
      this.sandbox.stub(sut, 'urlValid').returns(false);
      this.sandbox.spy(sut, 'notFound');
      sut.server(request, response);
      return assert(sut.notFound.calledOnce);
    });
    it('should call goPOST if method is POST', function () {
      this.sandbox.stub(sut, 'urlValid').returns(true);
      request.method = 'POST';
      this.sandbox.spy(sut, 'goPOST');
      sut.server(request, response);
      return assert(sut.goPOST.calledOnce);
    });
    it('should call goPUT if method is PUT', function () {
      this.sandbox.stub(sut, 'urlValid').returns(true);
      request.method = 'PUT';
      this.sandbox.spy(sut, 'goPUT');
      sut.server(request, response);
      return assert(sut.goPUT.calledOnce);
    });
    it('should call goGET if method is GET', function () {
      this.sandbox.stub(sut, 'urlValid').returns(true);
      request.method = 'GET';
      this.sandbox.spy(sut, 'goGET');
      sut.server(request, response);
      return assert(sut.goGET.calledOnce);
    });
    return it('should call goDELETE if method is DELETE', function () {
      this.sandbox.stub(sut, 'urlValid').returns(true);
      request.method = 'DELETE';
      this.sandbox.spy(sut, 'goDELETE');
      sut.server(request, response);
      return assert(sut.goDELETE.calledOnce);
    });
  });
  return describe('POST data handlers', function () {
    beforeEach(function () {
      request.on = function (event, callback) {
        return callback();
      };
      return this.sandbox.stub(sut, 'contract').returns(null);
    });
    describe('goPUT', function () {
      return it('should send not supported if there is no id in the url', function () {
        this.sandbox.stub(sut, 'getId').returns('');
        this.sandbox.spy(sut, 'notSupported');
        sut.goPUT(request, response);
        return assert(sut.notSupported.calledOnce);
      });
    });
    describe('processPUT', function () {
      it('should update item if data is JSON parsable', function () {
        var data;
        data = '{"property":"value"}';
        sut.processPUT('any id', data, response);
        return assert(endpoints.update.calledOnce);
      });
      it('should not update item if data isnt JSON parsable', function () {
        var data;
        data = '<H#rg';
        sut.processPUT('any id', data, response);
        return assert(endpoints.update.callCount === 0);
      });
      return it('should return BAD REQUEST when contract is violated', function () {
        var data;
        data = '{"property":"value"}';
        sut.contract.returns([]);
        this.sandbox.spy(sut, 'badRequest');
        sut.processPUT('any id', data, response);
        assert(sut.badRequest.calledOnce);
        return assert(sut.contract.calledOnce);
      });
    });
    describe('goPOST', function () {
      return it('should send not supported if there is an id in the url', function () {
        this.sandbox.stub(sut, 'getId').returns('123');
        this.sandbox.spy(sut, 'notSupported');
        sut.goPOST(request, response);
        return assert(sut.notSupported.calledOnce);
      });
    });
    describe('processPOST', function () {
      it('should create item if data is JSON parsable', function () {
        var data;
        data = '{"property":"value"}';
        sut.processPOST(data, response, request);
        return assert(endpoints.create.calledOnce);
      });
      it('should not create item if data isnt JSON parsable', function () {
        var data;
        data = '<H#rg';
        sut.processPOST(data, response, request);
        return assert(endpoints.create.callCount === 0);
      });
      return it('should return BAD REQUEST when contract is violated', function () {
        var data;
        data = '{"property":"value"}';
        sut.contract.returns([]);
        this.sandbox.spy(sut, 'badRequest');
        sut.processPOST(data, response, request);
        assert(sut.badRequest.calledOnce);
        return assert(sut.contract.calledOnce);
      });
    });
    describe('goDELETE', function () {
      it('should send not supported for the root url', function () {
        this.sandbox.stub(sut, 'getId').returns('');
        this.sandbox.spy(sut, 'notSupported');
        sut.goDELETE(request, response);
        return assert(sut.notSupported.calledOnce);
      });
      return it('should delete item if id was gathered', function () {
        this.sandbox.stub(sut, 'getId').returns('123');
        sut.goDELETE(request, response);
        return assert(endpoints.delete.calledOnce);
      });
    });
    return describe('goGET', function () {
      it('should gather all for the root url', function () {
        this.sandbox.stub(sut, 'getId').returns('');
        sut.goGET(request, response);
        return assert(endpoints.gather.calledOnce);
      });
      return it('should retrieve item if id was gathered', function () {
        this.sandbox.stub(sut, 'getId').returns('123');
        sut.goGET(request, response);
        return assert(endpoints.retrieve.calledOnce);
      });
    });
  });
});
