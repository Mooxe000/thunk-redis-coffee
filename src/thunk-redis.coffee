#!
# * thunk-redis - index.js
# *
# * MIT Licensed
#
RedisClient = require './lib/client'
tool = require './lib/tool'
defaultPort = 6379
defaultHost = 'localhost'

exports.createClient = (port, host, options) ->
  netOptions = undefined
  if typeof port is 'string'
    netOptions = path: port
    options = host
  else
    netOptions =
      port: port or defaultPort
      host: host or defaultHost

    if typeof port isnt 'number'
      netOptions.port = defaultPort
      options = port
    else if typeof host isnt 'string'
      netOptions.host = defaultHost
      options = host

  options = options or {}
  options.noDelay =
    if not options.noDelay?
    then true
    else !!options.noDelay
  options.keepAlive =
    if not options.keepAlive?
    then true
    else !!options.keepAlive
  options.timeout =
    if options.timeout > 0
    then Math.floor options.timeout
    else 0
  options.retryDelay =
    if options.retryDelay > 0
    then Math.floor options.retryDelay
    else 5000
  options.maxAttempts =
    if options.maxAttempts > 0
    then Math.floor options.maxAttempts
    else 5
  options.commandsHighWater =
    if options.commandsHighWater >= 1
    then Math.floor options.commandsHighWater
    else 10000
  options.database =
    if options.database > 0
    then Math.floor options.database
    else 0
  options.authPass = (
    options.authPass or ''
  ) + ''
  options.returnBuffers = !!options.returnBuffers
  new RedisClient netOptions, options

exports.log = tool.log