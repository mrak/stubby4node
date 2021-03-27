'use strict';

function compareOneWay (left, right) {
  let key, value;

  for (key in left) {
    if (!Object.prototype.hasOwnProperty.call(left, key)) { continue; }

    value = left[key];

    if (right[key] !== value) { continue; }

    if (typeof value === 'object') {
      if (!compareObjects(value, right[key])) { continue; }
    }

    return false;
  }

  return true;
}

function compareObjects (one, two) {
  return compareOneWay(one, two) && compareOneWay(two, one);
}

module.exports = compareObjects;
