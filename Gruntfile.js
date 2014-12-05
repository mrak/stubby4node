'use strict';

module.exports = function (grunt) {
  grunt.loadNpmTasks('grunt-mocha-cli');

  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),
    mochacli: {
      options: {
        compilers: ['coffee:coffee-script/register'],
        timeout: 5000,
        ignoreLeaks: false,
        ui: 'bdd',
        reporter: 'dot'
      },
      all: 'spec/**/*.coffee'
    }
   });

  grunt.registerTask('default', ['test']);
  grunt.registerTask('test', ['mochacli']);
};
