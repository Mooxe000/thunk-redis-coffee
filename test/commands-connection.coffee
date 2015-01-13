#global describe, it, before, after, beforeEach, afterEach
should = require 'should'
thunks = require 'thunks'
redis = require '../index'

module.exports = ->

  describe 'commands:Connection', ->
    client = undefined

    before ->
      client = redis.createClient
        database: 0
        debugMode: false

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

    it 'client.echo', (done) ->
      client.echo(
        'hello world!'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal 'hello world!'
          @echo 123
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal '123'
          return
      ) done
      return

    it 'client.ping', (done) ->
      client.ping()(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal 'PONG'
          return
      ) done
      return

    it 'client.select', (done) ->
      client.select(10)(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal 'OK'
          @select 99
      )(
        (error, res) ->
          should(error).be.instanceOf Error
          should(res).be.equal `undefined`
          return
      ) done
      return

    it 'client.auth', (done) ->
      client.auth('123456')(
        (error, res) ->
          should(error).be.instanceOf Error
          should(res).be.equal `undefined`
          @config 'set', 'requirepass', '123456'
      )(
        (error, res) ->
        should(error).be.equal null
        should(res).be.equal 'OK'
        @auth '123456'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal 'OK'
          @config 'set', 'requirepass', ''
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal 'OK'
          return
      ) done
      return

    it 'client.quit', (done) ->
      client.quit()(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal 'OK'
          return
      ) done
      return

    return

  return