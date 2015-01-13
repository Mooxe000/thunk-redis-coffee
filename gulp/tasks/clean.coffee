echo = console.log
del = require 'del'

module.exports = (cb) ->
  del [
    'dist/*'
    '.tmp'
    'trash'
  ], cb