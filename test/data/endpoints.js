'use strict';
module.exports = function (metadata) {
  var post = JSON.parse(metadata.data.post);
  return JSON.stringify({title: post.title});
};
