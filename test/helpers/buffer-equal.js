'use strict';

module.exports = function bufferEqual (l, r) {
  if (!Buffer.isBuffer(l)) return undefined;
  if (!Buffer.isBuffer(r)) return undefined;
  if (typeof l.equals === 'function') return l.equals(r);
  if (l.length !== r.length) return false;
  for (let i = 0; i < l.length; i++) if (l[i] !== r[i]) return false;
  return true;
};
