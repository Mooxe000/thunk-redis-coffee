echo = console.log
runSequence = require 'run-sequence'

module.exports = ->
  runSequence 'clean'
  , 'build', 'mocha'