var CLI = require('../src/console/cli');
var stubby = new (require('../src/main').Stubby);
var options = CLI.getArgs();

stubby.start(options);

process.on('SIGHUP', function() {
  stubby.delete(function () { stubby.start(options); });
})
