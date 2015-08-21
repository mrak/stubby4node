'use strict';

var times = require('../prototype/times'); // eslint-disable-line

function spacing(length) {
  if (length == null) { length = 0; }
  return ' '.times(length);
}

function wrap(tokens, continuation, columns) {
  var wrapped, gutter;

  if (continuation == null) { continuation = 0; }
  if (columns == null) { columns = process.stdout.columns; }

  if (continuation + tokens.join(' ').length <= columns) { return tokens.join(' '); }

  wrapped = '';
  gutter = spacing(continuation);

  tokens.forEach(function (token) {
    var lengthSoFar = continuation + wrapped.replace(/\n/g, '').length % columns || columns;

    if (lengthSoFar + token.length > columns) {
      wrapped += '\n' + gutter + token;
    } else {
      wrapped += ' ' + token;
    }
  });

  return wrapped.trim();
}

module.exports = {
  spacing: spacing,
  wrap: wrap
};
