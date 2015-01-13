#global describe, it, before, after, beforeEach, afterEach
should = require 'should'
thunks = require 'thunks'
redis = require '../index'

module.exports = ->
  describe 'commands:Script', ->
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

    it 'client.eval', (done) ->
      Thunk = thunks()
      client.eval(
        'return {KEYS[1],KEYS[2],ARGV[1],ARGV[2]}', 2, 'key1', 'key2', 'first', 'second')
      (
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            'key1'
            'key2'
            'first'
            'second'
          ]
          @eval 'return redis.call(\'set\',KEYS[1],\'bar\')', 1, 'foo'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal 'OK'
          Thunk.all (
            @get 'foo'
          ), @eval 'return redis.call(\'get\',\'foo\')', 0
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            'bar'
            'bar'
          ]
          Thunk.all (
            @lpush 'list', 123
          ), @eval 'return redis.call(\'get\', \'list\')', 0
      )(
        (error, res) ->
          should(error).be.instanceOf Error
          @eval 'return redis.pcall(\'get\', \'list\')', 0
      )(
        (error, res) ->
          should(error).be.instanceOf Error
          return
      ) done
      return

    it 'client.script, client.evalsha', (done) ->
      Thunk = thunks()
      sha = null
      client.script(
        'load', 'return \'hello thunk-redis\''
      )(
        (error, res) ->
          should(error).be.equal null
          sha = res
          @evalsha res, 0
      )(
        (error, res) ->
          should(res).be.equal 'hello thunk-redis'
          @script 'exists', sha
      )(
        (error, res) ->
          should(res).be.eql [1]
          Thunk.all (
            @script 'flush'
          ), @script 'exists', sha
      )(
        (error, res) ->
          should(res).be.eql [
            'OK'
            [0]
          ]
          @script 'kill'
      )(
        (error, res) ->
          should(error).be.instanceOf Error
          return
      ) done
      return

    return

  return