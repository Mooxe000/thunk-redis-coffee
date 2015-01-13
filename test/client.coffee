#global describe, it, before, after, beforeEach, afterEach
should = require 'should'
redis = require '../index'

module.exports = ->

  # Create Client
  describe 'createClient', ->
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

    it 'redis.createClient(options)', (done) ->
      client = redis.createClient(
        database: 1
        debugMode: false
      )
      client.get('test')(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal time
          @clientEnd()
          return
      ) done
      return

    it 'redis.createClient(port, options)', (done) ->
      client = redis.createClient 6379,
        database: 1
      client.get('test')(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal time
          @clientEnd()
          return
      ) done
      return

    it 'redis.createClient(port, host, options)', (done) ->
      client = redis.createClient 6379, 'localhost',
        database: 1
      client.get('test')(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal time
          @clientEnd()
          return
      ) done
      return

    return

  return