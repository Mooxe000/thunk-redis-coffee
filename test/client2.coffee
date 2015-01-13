#global describe, it, before, after, beforeEach, afterEach
should = require 'should'
redis = require '../index'

module.exports = ->

  describe 'createClient2', ->
    time = '' + Date.now()

    it 'redis.createClient()', (done) ->
      connect = false
      client = redis.createClient()

      client.on 'connect', ->
        connect = true
        return

      client.info()(
        (error, res) ->
          should(error).be.equal null
          should(connect).be.equal true
          should(res.redis_version).be.type 'string'
          @select 1
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal 'OK'
          @set 'test', time
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal 'OK'
          @clientEnd()
          return
      ) done
      return

    it 'redis.createClient(path, options)', (done) ->
      connect = false
      client = redis.createClient '/tmp/redis2.sock',
        database: 1

      client.on 'connect', ->
        connect = true
        return

      client.info()(
        (error, res) ->
          should(error).be.equal null
          should(connect).be.equal true
          should(res.redis_version).be.type 'string'
          @clientEnd()
      ) done
      return

    return

  return