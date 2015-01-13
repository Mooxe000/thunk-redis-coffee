net = require 'net'
util = require 'util'
Thunk = do require 'thunks'
resp = require 'respjs'
tool = require './tool'

initSocket = (redis, options, socketState) ->

  waitForAuth = false
  waitForSelect = false
  socket = redis._socket = net.createConnection options

  socket.setNoDelay redis._options.noDelay
  socket.setKeepAlive redis._options.keepAlive
  socket.setTimeout redis._options.timeout

  socket.pendingWatcher = null
  socket.redisConnected = false
  socket.commandsHighWater = redis._options.commandsHighWater
  socket.returnBuffers = redis._options.returnBuffers
  socket.debugMode = redis._options.debugMode

  tool.setPrivate socket, 'commandQueue', socketState.commandQueue
  tool.setPrivate socket, 'frequency', socketState.frequency

  checkReady = ->
    return execQueue redis, true  if waitForAuth or waitForSelect
    redis._redisState.connected = socket.redisConnected = true
    redis.emit 'connect'
    execQueue redis
    return

  if redis._options.authPass
    waitForAuth = true
    redis.auth(redis._options.authPass) (error) ->
      return socket.emit('error', error)  if error
      waitForAuth = false
      checkReady()
      return

  if redis._options.database
    waitForSelect = true
    redis.select(redis._options.database) (error) ->
      return socket.emit('error', error)  if error
      waitForSelect = false
      checkReady()
      return

  socket

  .on 'connect', checkReady

  .on 'data', (chunk) ->
    reply = socket.pendingWatcher

    tool.log socketChunk: chunk  if socket.debugMode
    return redis.emit 'error', (
      new Error 'Unexpected reply: ' + chunk
    )  unless reply
    reply.resp = initResp redis, reply  unless reply.resp
    reply.resp.feed chunk
    return

  .on 'error', (error) ->
    flushAll socket, error
    redis.emit 'error', error
    return

  .on 'close', (hadError) ->
    flushAll socket, new Error 'The redis connection was closed'
    redis.emit 'close', hadError
    return

  .on 'timeout', ->
    error = new Error 'The redis connection was timeout'
    redis.emit 'timeout'
    if socketState.attempts <= redis._options.maxAttempts
      flushPending socket, error
      socket.removeAllListeners()
      socket.destroy()

      redis.emit 'reconnecting',
        delay: redis._options.retryDelay
        attempts: ++socketState.attempts

      setTimeout ->
        initSocket redis, options,
          attempts: socketState.attempts
          commandQueue: socket.commandQueue
          frequency: socket.frequency
        return
      , redis._options.retryDelay
    else
      flushAll socket, error
      redis.end()

    return

  .on 'end', ->
    flushAll socket, new Error 'The redis connection was ended'
    redis.end()
    return

  .on 'queueDrain', ->
    redis.emit 'drain'
    return

  return

initResp = (redis, reply) ->

  socket = redis._socket
  redisState = redis._redisState

  new resp.Resp(
    expectResCount: reply.commands.length
    returnBuffers: socket.returnBuffers
  )

  .on 'error', (error) ->
    tool.log respError: error  if socket.debugMode
    flushPending socket, error
    redis.emit 'error', error
    return

  .on 'data', (data) ->
    tool.log respData: data  if socket.debugMode
    command = reply.commands[0]

    if redisState.monitorMode and (
      not command or command.name isnt 'quit'
    )
      return redis.emit 'monitor', data

    if isMessageReply data
      return redis.emit.apply redis, data

    if isUnSubReply data
      if redisState.pubSubMode and not data[2]
        redisState.pubSubMode = false
        @autoEnd reply.commands.length  if command
      unless command
        @end()
      else if data[0] is command.name
        reply.commands.shift()
        command.callback()
      return redis.emit.apply redis, data

    reply.commands.shift()

    unless command
      return redis.emit 'error'
      , new Error 'Unexpected reply: ' + data

    if util.isError(data)
      return command.callback(data)

    if command.name is 'monitor'
      redisState.monitorMode = true
      @autoEnd()
      return command.callback(null, data)

    if isSubReply(data)
      # (pub)subscribe can generate many replies. All are emitted as events.
      unless redisState.pubSubMode
        redisState.pubSubMode = true
        @autoEnd()
      command.callback()
      return redis.emit.apply(redis, data)

    command.callback null, data

  .on 'end', ->
    socket.pendingWatcher = null
    execQueue redis
    return

sendCommand = (redis, command, args, additionalCallbacks) ->
  Thunk.call redis, (callback) ->
    buffer = undefined
    if redis._redisState.ended
      return callback new Error 'The redis connection was ended'
    args = []  unless Array.isArray(args)
    args.unshift command
    try
      buffer = resp.bufferify args
    catch error
      return callback error
    @_socket.commandQueue.push new Command command, buffer, callback, additionalCallbacks
    execQueue @
    return

# This Command constructor is ever so slightly faster than using an object literal, but more importantly, using
# a named constructor helps it show up meaningfully in the V8 CPU profiler and in heap snapshots.
Command = (command, data, callback, additionalCallbacks) ->
  @name = command
  @data = data
  @callback = callback
  @additionalCallbacks = additionalCallbacks or 0
  return

noop = ->

execQueue = (redis, init) ->
  socket = redis._socket

  return  if not init and not socket.redisConnected
  return socket.emit 'queueDrain'  unless socket.commandQueue.length
  if redis._redisState.pubSubMode or redis._redisState.monitorMode
    flushForMonitor socket  if redis._redisState.monitorMode
  else if socket.pendingWatcher
    return
  else
    socket.pendingWatcher = commands: []

  pendingCommands = 0
  count = socket.commandsHighWater
  pendingWatcher = socket.pendingWatcher

  while socket.commandQueue.length and count--
    command = socket.commandQueue.shift()

    tool.log socketWrite: command.data.toString()  if socket.debugMode

    pendingWatcher.commands.push
      name: command.name
      callback: command.callback

    while command.additionalCallbacks--
      pendingWatcher.commands.push
        name: command.name
        callback: noop

    pendingCommands++

    flushForMonitor socket  if command.name is 'monitor'
    break  unless socket.write(command.data)

  socket.frequency[pendingCommands] = 1 + (
    socket.frequency[pendingCommands] or 0
  )

  return

flushForMonitor = (socket) ->
  error = new Error 'Only QUIT allowed in this monitor.'
  queue = socket.commandQueue
  queue.shift().callback error  while queue.length and queue[0].name isnt 'quit'
  return

flushPending = (socket, error) ->
  return  unless socket.pendingWatcher
  tool.each socket.pendingWatcher.commands, (command) ->
    command.callback error
    return
  , null, true
  socket.pendingWatcher = null
  return

flushAll = (socket, error) ->
  flushPending socket, error
  queue = socket.commandQueue
  queue.shift().callback error  while queue.length
  return

messageTypes =
  message: true
  pmessage: true
isMessageReply = (reply) ->
  reply and messageTypes.hasOwnProperty(reply[0])

subReplyTypes =
  subscribe: true
  psubscribe: true
isSubReply = (reply) ->
  reply and subReplyTypes.hasOwnProperty(reply[0])

unSubReplyTypes =
  unsubscribe: true
  punsubscribe: true
isUnSubReply = (reply) ->
  reply and unSubReplyTypes.hasOwnProperty(reply[0])

exports.initSocket = initSocket
exports.sendCommand = sendCommand