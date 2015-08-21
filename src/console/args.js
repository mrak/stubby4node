'use strict';

var pp = require('./prettyprint');
var UNARY_FLAGS = /^-[a-zA-Z]+$/;
var ANY_FLAG = /^-.+$/;

function findOption(option, argv) {
  var argIndex = -1;

  if (option.flag != null) {
    argIndex = indexOfFlag(option, argv);
  }

  if (argIndex === -1 && option.name != null) {
    argIndex = argv.indexOf('--' + option.name);
  }

  return argIndex;
}

function indexOfFlag(option, argv) {
  var index = -1;

  argv.forEach(function (flag) {
    if (!UNARY_FLAGS.test(flag)) { return; }
    if (flag.indexOf(option.flag) === -1) { return; }
    index = argv.indexOf(flag);
  });

  return index;
}

function optionSkipped(index, argv) {
  return ANY_FLAG.test(argv[index + 1]);
}

function unaryCheck(option, argv) {
  if (option.name != null && argv.indexOf('--' + option.name) !== -1) {
    return true;
  }
  if (option.flag == null) {
    return false;
  }
  return indexOfFlag(option, argv) !== -1;
}

function pullPassedValue(option, argv) {
  var argIndex;

  if (option.param == null) { return unaryCheck(option, argv); }

  argIndex = findOption(option, argv);

  if (argIndex === -1) { return option.default; }
  if (argv[argIndex + 1] == null) { return option.default; }
  if (!optionSkipped(argIndex, argv)) { return argv[argIndex + 1]; }

  return option.default;
}

function parse(options, argv) {
  var args = {};

  if (argv == null) { argv = process.argv; }

  options.forEach(function (option) {
    if (option.default == null) { option.default = null; }
    args[option.name || option.flag] = pullPassedValue(option, argv);
  });

  return args;
}

function helpText(options, programName) {
  var inlineList = [];
  var firstColumn = {};
  var helpLines = [];
  var gutter = 3;

  options.forEach(function (option) {
    var param = option.param != null
                ? ' <' + option.param + '>'
                : '';

    firstColumn[option.name] = '-' + option.flag + ', --' + option.name + param;
    inlineList.push('[-' + option.flag + param + ']');
    gutter = Math.max(gutter, firstColumn[option.name].length + 3);
  });

  options.forEach(function (option) {
    var helpLine = firstColumn[option.name];
    helpLine += pp.spacing(gutter - helpLine.length);
    helpLine += pp.wrap(option.description.split(' '), gutter);
    helpLines.push(helpLine);
  });

  return programName + ' ' + pp.wrap(inlineList, programName.length + 1) + '\n\n' + helpLines.join('\n');
}

module.exports = {
  parse: parse,
  helpText: helpText
};
