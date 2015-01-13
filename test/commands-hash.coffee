#global describe, it, before, after, beforeEach, afterEach
should = require 'should'
thunks = require 'thunks'
JSONKit = require 'jsonkit'
redis = require '../index'

module.exports = ->

  describe 'commands:Hash', ->
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

    it 'client.hdel, client.hexists', (done) ->
      Thunk = thunks (error) ->
        console.error error
        done error
        return

      Thunk.call(
        client, client.hdel 'hash', 'key'
      )(
        (error, res) ->
          should(res).be.equal 0
          @hexists 'hash', 'key'
      )(
        (error, res) ->
          should(res).be.equal 0
          @hset 'hash', 'key', 123
      )(
        (error, res) ->
          should(res).be.equal 1
          @hexists 'hash', 'key'
      )(
        (error, res) ->
          should(res).be.equal 1
          @hdel 'hash', 'key'
      )(
        (error, res) ->
          should(res).be.equal 1
          @hmset 'hash',
            key1: 1
            key2: 2
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          @hdel 'hash', 'key1', 'key2', 'key3'
      )(
        (error, res) ->
          should(res).be.equal 2
          return
      ) done
      return

    it 'client.hget, client.hgetall, client.hkeys', (done) ->

      Thunk = thunks (error) ->
        console.error error
        done error
        return

      Thunk.call(
        client, client.hget 'hash', 'key'
      )(
        (error, res) ->
          should(res).be.equal null
          @hgetall 'hash'
      )(
        (error, res) ->
          should(res).be.eql {}
          @hkeys 'hash'
      )(
        (error, res) ->
          should(res).be.eql []
          @hmset 'hash',
            key1: 1
            key2: 2
            key3: 3
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          @hget 'hash', 'key3'
      )(
        (error, res) ->
          should(res).be.equal '3'
          @hgetall 'hash'
      )(
        (error, res) ->
          should(res).be.eql
            key1: '1'
            key2: '2'
            key3: '3'
          @hkeys 'hash'
      )(
        (error, res) ->
          should(res).be.eql [
            'key1'
            'key2'
            'key3'
          ]
          return
      ) done
      return

    it 'client.hincrby, client.hincrbyfloat', (done) ->
      Thunk0 = thunks()
      Thunk = thunks (error) ->
        console.error error
        done error
        return

      Thunk.call(
        client, client.hincrby 'hash', 'key', -1
      )(
        (error, res) ->
          should(res).be.equal -1
          @hincrby 'hash', 'key', -9
      )(
        (error, res) ->
          should(res).be.equal -10
          @hincrby 'hash', 'key', 15
      )(
        (error, res) ->
          should(res).be.equal 5
          @hincrbyfloat 'hash', 'key', -1.5
      )(
        (error, res) ->
          should(res).be.equal '3.5'
          @hset 'hash', 'key1', 'hello'
      )(
        (error, res) ->
          should(res).be.equal 1
          Thunk0.call(this, @hincrbyfloat('hash', 'key1', 1)) (error, res) ->
            should(error).be.instanceOf Error
            return
      ) done
      return

    it 'client.hlen, client.hmget, client.hmset', (done) ->
      Thunk0 = thunks()
      Thunk = thunks (error) ->
        console.error error
        done error
        return

      Thunk.call(
        client, client.hlen 'hash'
      )(
        (error, res) ->
          should(res).be.equal 0
          @hmget 'hash', 'key1', 'key2'
      )(
        (error, res) ->
          should(res).be.eql [
            null
            null
          ]
          @hmset 'hash',
            key1: 1
            key2: 2
            key3: 3
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          @hmget 'hash', 'key3', 'key', 'key1'
      )(
        (error, res) ->
          should(res).be.eql [
            '3'
            null
            '1'
          ]
          @hmset 'hash', 'key', 0, 'key3', 'hello'
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          @hlen 'hash'
      )(
        (error, res) ->
          should(res).be.equal 4
          @hmget 'hash', 'key3', 'key'
      )(
        (error, res) ->
          should(res).be.eql [
            'hello'
            '0'
          ]
          @set 'key', 'hello'
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          Thunk0.call(
            this, @hlen 'key'
          )(
            (error, res) ->
              should(res).be.equal 0
              @hmget 'key', 'key3'
          )(
            (error, res) ->
              should(res).be.eql [null]
              @hmset 'key', 'key3', 'hello'
          ) (error, res) ->
            should(error).be.instanceOf Error
            return
      ) done
      return

    it 'client.hset, client.hsetnx, client.hvals', (done) ->
      Thunk0 = thunks()
      Thunk = thunks (error) ->
        console.error error
        done error
        return

      Thunk.call(
        client, client.hvals 'hash'
      )(
        (error, res) ->
          should(res).be.eql []
          @hset 'hash', 'key', 123
      )(
        (error, res) ->
          should(res).be.equal 1
          @hset 'hash', 'key', 456
      )(
        (error, res) ->
          should(res).be.equal 0
          @hget 'hash', 'key'
      )(
        (error, res) ->
          should(res).be.equal '456'
          @hsetnx 'hash', 'key', 0
      )(
        (error, res) ->
          should(res).be.equal 0
          @hget 'hash', 'key'
      )(
        (error, res) ->
          should(res).be.equal '456'
          @hsetnx 'hash', 'key1', 'hello'
      )(
        (error, res) ->
          should(res).be.equal 1
          @hsetnx 'hash1', 'key1', 'hello'
      )(
        (error, res) ->
          should(res).be.equal 1
          @
          @hget('hash', 'key1')
      )(
        (error, res) ->
          should(res).be.equal 'hello'
          @
          @hget('hash1', 'key1')
      )(
        (error, res) ->
          should(res).be.equal 'hello'
          @
          @hvals('hash1')
      )(
        (error, res) ->
          should(res).be.eql ['hello']
          return
      ) done
      return

    it 'client.hscan', (done) ->

      Thunk = thunks (error) ->
        console.error error
        done error
        return

      count = 100
      data = {}
      scanKeys = {}

      data['key' + count] = count  while count--

      fullScan = (key, cursor) ->
        client.hscan(key, cursor) (error, res) ->
          JSONKit.each res[1], (value, key) ->
            scanKeys[key] = value
            return

          return res  if res[0] is '0'
          fullScan key, res[0]

      Thunk.call(
        client, client.hscan 'hash', 0
      )(
        (error, res) ->
          should(res).be.eql [
            '0'
            {}
          ]
          client.hmset 'hash', data
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          fullScan 'hash', 0
      )(
        (error, res) ->
          JSONKit.each data, (value, key) ->
            should(
              scanKeys[key] >= 0
            ).be.equal true
            return
          @hscan 'hash', '0', 'count', 20
      )(
        (error, res) ->
          should(
            res[0] >= 0
          ).be.equal true
          should(
            Object.keys(
              res[1]
            ).length > 0
          ).be.equal true
          @hscan 'hash', '0', 'count', 200, 'match', '*0'
      )(
        (error, res) ->
          should(
            res[0] is '0'
          ).be.equal true
          should(
            Object.keys(
              res[1]
            ).length is 10
          ).be.equal true
          return
      ) done
      return

    return

  return