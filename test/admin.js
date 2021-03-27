'use strict';

const Admin = require('../src/portals/admin').Admin;
const assert = require('assert');

require('../src/console/out').quiet = true;

describe('Admin', function () {
  let endpoints, request, response, sut;

  beforeEach(function () {
    this.sandbox.spy(console, 'info');

    endpoints = {
      create: this.sandbox.stub(),
      retrieve: this.sandbox.spy(),
      update: this.sandbox.spy(),
      delete: this.sandbox.spy(),
      deleteAll: this.sandbox.spy(),
      gather: this.sandbox.stub()
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
      const url = '/';
      const result = sut.urlValid(url);

      assert(result);
    });

    it('should not accept urls with a-z in them', function () {
      const url = '/abcdefhijklmnopqrstuvwxyz';
      const result = sut.urlValid(url);

      assert(!result);
    });

    it('should accept urls of digits', function () {
      const url = '/1';
      const result = sut.urlValid(url);

      assert(result);
    });

    it('should not accept urls not beginning in /', function () {
      const url = '123456';
      const result = sut.urlValid(url);

      assert(!result);
    });

    it('should not accept urls beginning with 0', function () {
      const url = '/012';
      const result = sut.urlValid(url);

      assert(!result);
    });
  });

  describe('getId', function () {
    it('should get valid id from url', function () {
      const id = '123';
      const url = '/' + id;
      const actual = sut.getId(url);

      assert.strictEqual(actual, id);
    });

    it('should return nothing for root url', function () {
      const url = '/';
      const actual = sut.getId(url);
      assert(!actual);
    });
  });

  describe('notSupported', function () {
    it('should status code with "405 Not Supported" code and end response', function () {
      sut.notSupported(response);

      assert.strictEqual(response.statusCode, 405);
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

      assert.strictEqual(response.statusCode, 204);
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
      const content = {};
      sut.ok(response, content);
      assert(response.end.calledOnce);
      assert.strictEqual(response.end.args[0].length, 1);
    });

    it('should write nothing if content is null', function () {
      const content = null;
      sut.ok(response, content);
      assert.strictEqual(response.write.callCount, 0);
    });

    it('should write nothing if content is undefined', function () {
      sut.ok(response);
      assert.strictEqual(response.write.callCount, 0);
    });
  });

  describe('created', function () {
    let id = null;

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
      const expected = {
        Location: request.headers.host + '/' + id
      };

      sut.created(response, request, id);

      assert.deepStrictEqual(response.writeHead.args[0][1], expected);
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
      this.sandbox.stub(sut, 'goPUT');
      request.method = 'PUT';

      sut.server(request, response);

      assert(sut.goPUT.calledOnce);
    });

    it('should call goGET if method is GET', function () {
      this.sandbox.stub(sut, 'urlValid').returns(true);
      this.sandbox.stub(sut, 'goGET');

      request.method = 'GET';
      sut.server(request, response);
      assert(sut.goGET.calledOnce);
    });

    it('should call goDELETE if method is DELETE', function () {
      this.sandbox.stub(sut, 'urlValid').returns(true);
      this.sandbox.stub(sut, 'goDELETE');
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
        const data = '{"property":"value"}';

        sut.processPUT('any id', data, response);

        assert(endpoints.update.calledOnce);
      });

      it('should not update item if data isnt JSON parsable', function () {
        const data = '<H#rg';

        sut.processPUT('any id', data, response);

        assert.strictEqual(endpoints.update.callCount, 0);
      });

      it('should return BAD REQUEST when contract is violated', function () {
        const data = '{"property":"value"}';
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
        const data = '{"property":"value"}';
        endpoints.create.returns({ id: 1 });

        sut.processPOST(data, response, request);

        assert(endpoints.create.calledOnce);
      });

      it('should not create item if data isnt JSON parsable', function () {
        const data = '<H#rg';

        sut.processPOST(data, response, request);

        assert.strictEqual(endpoints.create.callCount, 0);
      });

      it('should return BAD REQUEST when contract is violated', function () {
        const data = '{"property":"value"}';
        sut.contract.returns([]);
        this.sandbox.spy(sut, 'badRequest');

        sut.processPOST(data, response, request);

        assert(sut.badRequest.calledOnce);
        assert(sut.contract.calledOnce);
      });
    });

    describe('goDELETE', function () {
      it('should delete all stubs when calling from the root url', function () {
        this.sandbox.stub(sut, 'getId').returns('');

        request.url = '/';
        sut.goDELETE(request, response);

        assert(endpoints.deleteAll.calledOnce);
      });

      ['/test', '/1/test'].forEach(function (url) {
        it('should not delete all stubs when calling from non-root urls: ' + url, function () {
          this.sandbox.stub(sut, 'getId').returns('');

          request.url = url;
          sut.goDELETE(request, response);

          assert(endpoints.deleteAll.notCalled);
          assert.strictEqual(response.statusCode, 405);
        });
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
        endpoints.gather.returns([]);

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
