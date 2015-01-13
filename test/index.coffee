#global describe, it, before, after, beforeEach, afterEach
should = require 'should'
redis = require '../index'
clientTest = require './client'

commandsConnection = require './commands-connection'
commandsHash = require './commands-hash'
commandsKey = require './commands-key'
commandsList = require './commands-list'
commandsPubsub = require './commands-pubsub'
commandsScript = require './commands-script'
commandsHyperLogLog = require './commands-hyperloglog'
commandsServer = require './commands-server'
commandsSet = require './commands-set'
commandsSortedSet = require './commands-sorted-set'
commandsString = require './commands-string'
commandsTransaction = require './commands-transaction'

describe 'thunk-redis', ->
  before (done) ->

    redis.createClient(
      database: 0
    ).flushdb()(
      (error, res) ->
        should(error).be.equal null
        should(res).be.equal 'OK'
        @dbsize()
    )(
      (error, res) ->
        should(error).be.equal null
        should(res).be.equal 0
        @select 1
    )(
      (error, res) ->
        should(error).be.equal null
        should(res).be.equal 'OK'
        @flushdb()
    )(
      (error, res) ->
        should(error).be.equal null
        should(res).be.equal 'OK'
        @dbsize()
    )(
      (error, res) ->
        should(error).be.equal null
        should(res).be.equal 0
        @clientEnd()
        return
    ) done
    return

  after ->
    setTimeout ->
      process.exit()
      return
    , 1000
    return


  clientTest()
  commandsKey()
  commandsSet()
  commandsHash()
  commandsList()
  commandsPubsub()
  commandsScript()
  commandsServer()
  commandsString()
  commandsSortedSet()
  commandsConnection()
  commandsHyperLogLog()
  commandsTransaction()

  try
    check = new Function 'return function*(){}'
    do require './chaos'
  catch e
    console.log "Not support generator!"

  return
