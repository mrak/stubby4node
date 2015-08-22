'use strict';

var Admin = require('../src/portals/admin').Admin;
var assert = require('assert');

require('../src/console/out').mute = true;

describe('Admin', function () {
  var endpoints, request, response, sut;

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
      var url = '/';
      var result = sut.urlValid(url);

      assert(result);
    });

    it('should not accept urls with a-z in them', function () {
      var url = '/abcdefhijklmnopqrstuvwxyz';
      var result = sut.urlValid(url);

      assert(!result);
    });

    it('should accept urls of digits', function () {
      var url = '/1';
      var result = sut.urlValid(url);

      assert(result);
    });

    it('should not accept urls not beginning in /', function () {
      var url = '123456';
      var result = sut.urlValid(url);

      assert(!result);
    });

    it('should not accept urls beginning with 0', function () {
      var url = '/012';
      var result = sut.urlValid(url);

      assert(!result);
    });
  });

  describe('getId', function () {
    it('should get valid id from url', function () {
      var id = '123';
      var url = '/' + id;
      var actual = sut.getId(url);

      assert(actual === id);
    });

    it('should return nothing for root url', function () {
      var url = '/';
      var actual = sut.getId(url);
      assert(!actual);
    });
  });

  describe('notSupported', function () {
    it('should status code with "405 Not Supported" code and end response', function () {
      sut.notSupported(response);

      assert(response.statusCode === 405);
      assert(response.end.calledOnce);
    });
  });

  describe('notFound', function () {
    it('should write header with "404 Not Found" code and end response', function () {
      sut.notFound(response);

      assert(response.writeHead.calledWith(404));
      assert(response.end.calledOnce);
    });
  });

  describe('serverError', function () {
    it('should write header with "500 Server Error" code and end response', function () {
      sut.serverError(response);

      assert(response.writeHead.calledWith(500));
      assert(response.end.calledOnce);
    });
  });

  describe('saveError', function () {
    it('should write header with "422 Uprocessable Entity" code and end response', function () {
      sut.saveError(response);

      assert(response.writeHead.calledWith(422));
      assert(response.end.calledOnce);
    });
  });

  describe('noContent', function () {
    it('should write header with "204 No Content" code and end response', function () {
      sut.noContent(response);

      assert(response.statusCode === 204);
      assert(response.end.calledOnce);
    });
  });

  describe('ok', function () {
    it('should write header with "200 OK" code and end response', function () {
      sut.ok(response);

      assert(response.writeHead.calledWith(200));
      assert(response.end.calledOnce);
    });

    it('should write JSON content if supplied', function () {
      var content = {};
      sut.ok(response, content);
      assert(response.end.calledOnce);
      assert(response.end.args[0].length === 1);
    });

    it('should write nothing if content is null', function () {
      var content;
      content = null;
      sut.ok(response, content);
      assert(response.write.callCount === 0);
    });

    it('should write nothing if content is undefined', function () {
      sut.ok(response);
      assert(response.write.callCount === 0);
    });
  });

  describe('created', function () {
    var id = null;

    beforeEach(function () {
      request.headers.host = 'testHost';
      id = '42';
    });

    it('should write header with "201 Content Created" code and end response', function () {
      sut.created(response, request, id);

      assert(response.writeHead.calledWith(201));
      assert(response.end.calledOnce);
    });

    it('should write header with Location set', function () {
      var expected = {
        Location: request.headers.host + '/' + id
      };

      sut.created(response, request, id);

      assert.deepEqual(response.writeHead.args[0][1], expected);
    });
  });

  describe('server', function () {
    it('should call notFound if url not valid', function () {
      this.sandbox.stub(sut, 'urlValid').returns(false);
      this.sandbox.spy(sut, 'notFound');

      sut.server(request, response);

      assert(sut.notFound.calledOnce);
    });

    it('should call goPOST if method is POST', function () {
      this.sandbox.stub(sut, 'urlValid').returns(true);
      this.sandbox.spy(sut, 'goPOST');
      request.method = 'POST';

      sut.server(request, response);

      assert(sut.goPOST.calledOnce);
    });

    it('should call goPUT if method is PUT', function () {
      this.sandbox.stub(sut, 'urlValid').returns(true);
      this.sandbox.spy(sut, 'goPUT');
      request.method = 'PUT';

      sut.server(request, response);

      assert(sut.goPUT.calledOnce);
    });

    it('should call goGET if method is GET', function () {
      this.sandbox.stub(sut, 'urlValid').returns(true);
      this.sandbox.spy(sut, 'goGET');

      request.method = 'GET';
      sut.server(request, response);
      assert(sut.goGET.calledOnce);
    });

    it('should call goDELETE if method is DELETE', function () {
      this.sandbox.stub(sut, 'urlValid').returns(true);
      this.sandbox.spy(sut, 'goDELETE');
      request.method = 'DELETE';

      sut.server(request, response);

      assert(sut.goDELETE.calledOnce);
    });
  });

  describe('POST data handlers', function () {
    beforeEach(function () {
      request.on = function (event, callback) {
        callback();
      };
      this.sandbox.stub(sut, 'contract').returns(null);
    });

    describe('goPUT', function () {
      it('should send not supported if there is no id in the url', function () {
        this.sandbox.stub(sut, 'getId').returns('');
        this.sandbox.spy(sut, 'notSupported');

        sut.goPUT(request, response);

        assert(sut.notSupported.calledOnce);
      });
    });

    describe('processPUT', function () {
      it('should update item if data is JSON parsable', function () {
        var data = '{"property":"value"}';

        sut.processPUT('any id', data, response);

        assert(endpoints.update.calledOnce);
      });

      it('should not update item if data isnt JSON parsable', function () {
        var data = '<H#rg';

        sut.processPUT('any id', data, response);

        assert(endpoints.update.callCount === 0);
      });

      it('should return BAD REQUEST when contract is violated', function () {
        var data = '{"property":"value"}';
        sut.contract.returns([]);
        this.sandbox.spy(sut, 'badRequest');

        sut.processPUT('any id', data, response);

        assert(sut.badRequest.calledOnce);
        assert(sut.contract.calledOnce);
      });
    });

    describe('goPOST', function () {
      it('should send not supported if there is an id in the url', function () {
        this.sandbox.stub(sut, 'getId').returns('123');
        this.sandbox.spy(sut, 'notSupported');

        sut.goPOST(request, response);

        assert(sut.notSupported.calledOnce);
      });
    });

    describe('processPOST', function () {
      it('should create item if data is JSON parsable', function () {
        var data = '{"property":"value"}';

        sut.processPOST(data, response, request);

        assert(endpoints.create.calledOnce);
      });

      it('should not create item if data isnt JSON parsable', function () {
        var data = '<H#rg';

        sut.processPOST(data, response, request);

        assert(endpoints.create.callCount === 0);
      });

      it('should return BAD REQUEST when contract is violated', function () {
        var data = '{"property":"value"}';
        sut.contract.returns([]);
        this.sandbox.spy(sut, 'badRequest');

        sut.processPOST(data, response, request);

        assert(sut.badRequest.calledOnce);
        assert(sut.contract.calledOnce);
      });
    });

    describe('goDELETE', function () {
      it('should send not supported for the root url', function () {
        this.sandbox.stub(sut, 'getId').returns('');
        this.sandbox.spy(sut, 'notSupported');

        sut.goDELETE(request, response);

        assert(sut.notSupported.calledOnce);
      });

      it('should delete item if id was gathered', function () {
        this.sandbox.stub(sut, 'getId').returns('123');

        sut.goDELETE(request, response);

        assert(endpoints.delete.calledOnce);
      });
    });

    describe('goGET', function () {
      it('should gather all for the root url', function () {
        this.sandbox.stub(sut, 'getId').returns('');

        sut.goGET(request, response);

        assert(endpoints.gather.calledOnce);
      });
      it('should retrieve item if id was gathered', function () {
        this.sandbox.stub(sut, 'getId').returns('123');

        sut.goGET(request, response);

        assert(endpoints.retrieve.calledOnce);
      });
    });
  });
});
