Thunk = require 'thunks'
util = require 'util'
tool = require './tool'
{
  initSocket
  sendCommand
} = require './socket'
{initCommands} = require './commands'
{EventEmitter} = require 'events'
connectionId = 0

RedisState = ->
  @connectionId = ++connectionId
  @database = 0
  @timestamp = Date.now()
  @monitorMode = false
  @pubSubMode = false
  @connected = false
  @ended = false
  return

RedisClient = (netOptions, options) ->
  EventEmitter.call this
  tool.setPrivate this, '_options', options
  tool.setPrivate this, '_redisState', new RedisState()
  initSocket this, netOptions,
    attempts: 1
    commandQueue: []
    frequency: {}
  return

util.inherits RedisClient, EventEmitter
initCommands RedisClient::

RedisClient::clientUnref = ->
  return if @_redisState.ended
  if @_redisState.connected
    @_socket.unref()
  else
    @once 'connect', ->
      @unref()
      return
  return

RedisClient::clientEnd = ->
  @_redisState.ended = true
  @_socket.end()
  @_socket.destroy()
  @removeAllListeners()
  return

RedisClient::clientState = ->
  state =
    frequency: {}
    commandQueueLength: @_socket.commandQueue.length

  tool.each @_redisState, (value, key) ->
    state[key] = value
    return

  tool.each @_socket.frequency, (value, key) ->
    state.frequency[key] = value
    return

  state

Object.freeze RedisClient::

module.exports = RedisClient
