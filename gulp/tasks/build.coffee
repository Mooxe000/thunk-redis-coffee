echo = console.log
gulp = require 'gulp'
coffee = require 'gulp-coffee'

module.exports = ->

  gulp.src [
    'src/**/*.coffee'
    '!src/examples/*.coffee'
  ]
  .pipe coffee
    bare: true
  .pipe gulp.dest 'dist'
