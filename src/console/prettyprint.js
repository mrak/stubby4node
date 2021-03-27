'use strict';

function prettyPrint (tokens, continuation = 0, columns = process.stdout.columns) {
  let wrapped;

  if (continuation + tokens.join(' ').length <= columns) { return tokens.join(' '); }

  wrapped = '';
  const gutter = ''.padEnd(continuation);

  tokens.forEach(function (token) {
    const lengthSoFar = continuation + wrapped.replace(/\n/g, '').length % columns || columns;

    if (lengthSoFar + token.length > columns) {
      wrapped += '\n' + gutter + token;
    } else {
      wrapped += ' ' + token;
    }
  });

  return wrapped.trim();
}

module.exports = prettyPrint;
