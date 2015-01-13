#global describe, it, before, after, beforeEach, afterEach
should = require 'should'
thunks = require 'thunks'
redis = require '../index'

module.exports = ->

  describe 'commands:Server', ->
    client = undefined

    before ->
      client = redis.createClient database: 0
      client.on 'error', (error) ->
        console.error 'redis client:', error
        return
      return

    beforeEach (done) ->
      client.flushdb()(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal 'OK'
          return
      ) done
      return

    after ->
      client.clientEnd()
      return

    it.skip 'client.bgrewriteaof', ->

    return

  return