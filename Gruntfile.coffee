module.exports = (grunt) ->

   grunt.loadNpmTasks 'grunt-contrib-coffee'
   grunt.loadNpmTasks 'grunt-contrib-watch'
   grunt.loadNpmTasks 'grunt-mocha-cli'

   grunt.initConfig
      pkg: grunt.file.readJSON 'package.json'

      mochacli:
         options:
            compilers: ['coffee:coffee-script']
         all: 'spec/**/*.coffee'

      coffee:
         src:
            expand: true
            cwd: 'src'
            src: ['**/*.coffee']
            dest: 'lib'
            ext: '.js'

         webroot:
            expand: true
            cwd: 'webrootSrc'
            src: ['**/*.coffee']
            dest: 'webroot'
            ext: '.js'

      watch:
         src:
            files: 'src/**/*.coffee'
            tasks: 'coffee:src'
         webroot:
            files: 'webroot/**/*.coffee'
            tasks: 'coffee:webroot'

   grunt.registerTask 'default', ['coffee', 'mochacli']
   grunt.registerTask 'test', ['mochacli']
