gulp = require 'gulp'
mocha = require 'gulp-mocha'

module.exports = ->

  gulp.src 'test/index.coffee',
    read: false
  .pipe mocha
    timeout: 8000