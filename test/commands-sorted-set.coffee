#global describe, it, before, after, beforeEach, afterEach
should = require 'should'
thunks = require 'thunks'
JSONKit = require 'jsonkit'
redis = require '../index'

module.exports = ->

  describe 'commands:Sorted Set', ->

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

    it 'client.zadd, client.zcard, client.zcount', (done) ->

      Thunk = thunks()

      Thunk.call(
        client, client.zcard 'zsetA'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal 0
          Thunk.all (
            @set 'key', 'abc'
          ), @zcard 'key'
      )(
        (error, res) ->
          should(error).be.instanceOf Error
          @zadd 'key', 0, 'a'
      )(
        (error, res) ->
          should(error).be.instanceOf Error
          Thunk.all (
            @zadd 'zsetA', 0, 'a', 1, 'b'
          ), (
            @zadd 'zsetA', 2, 'b', 3, 'c'
          ), @zcard 'zsetA'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            2
            1
            3
          ]
          @zcount 'zsetA', 2, 3
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal 2
          return
      ) done
      return

    it 'client.zincrby, client.zscore, client.zrange, client.zrangebyscore', (done) ->

      Thunk = thunks()

      Thunk.call(
        client, client.zadd 'zsetA', 2, 'a'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal 1
          Thunk.all (
            @zincrby 'zsetA', 10, 'a'
          ), @zscore 'zsetA', 'a'
      )(
        (error, res) ->
          should(res).be.eql [
            '12'
            '12'
          ]
          Thunk.all (
            @zincrby 'zsetA', 10, 'b'
          ), (
            @zincrby 'zsetA', -2, 'a'
          ), @zscore 'zsetA', 'b'
      )(
        (error, res) ->
          should(res).be.eql [
            '10'
            '10'
            '10'
          ]
          @zrange 'zsetA', 0, -1
      )(
        (error, res) ->
          should(res).be.eql [
            'a'
            'b'
          ]
          Thunk.all (
            @zincrby 'zsetA', 15, 'c'
          ), (
            @zincrby 'zsetA', 10, 'b'
          ), @zrange 'zsetA', 1, -1, 'WITHSCORES'
      )(
        (error, res) ->
          should(res).be.eql [
            '15'
            '20'
            [
              'c'
              '15'
              'b'
              '20'
            ]
          ]
          @zrangebyscore 'zsetA', '(10', 100, 'WITHSCORES'
      )(
        (error, res) ->
          should(res).be.eql [
            'c'
            '15'
            'b'
            '20'
          ]
          @zrangebyscore 'zsetA', '-inf', '+inf', 'LIMIT', 1, 1
      )(
        (error, res) ->
          should(res).be.eql ['c']
          return
      ) done
      return

    it 'client.zrank, client.zrevrank', (done) ->

      Thunk = thunks()

      Thunk.call(
        client, client.zadd 'zsetA', 1, 'a', 2, 'b', 3, 'c'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal 3
          Thunk.all (
            @zrank 'zsetA', 'a'
          ), (
            @zrank 'zsetA', 'c'
          ), @zrank 'zsetA', 'x'
      )(
        (error, res) ->
          should(res).be.eql [
            0
            2
            null
          ]
          Thunk.all (
            @zrevrank 'zsetA', 'a'
          ), (
            @zrevrank 'zsetA', 'c'
          ), @zrevrank 'zsetA', 'x'
      )(
        (error, res) ->
          should(res).be.eql [
            2
            0
            null
          ]
          return
      ) done
      return

    it 'client.zrem, client.zremrangebyrank, client.zremrangebyscore', (done) ->
      Thunk = thunks()

      Thunk.call(
        client, client.zadd 'zsetA', 1, 'a', 2, 'b', 3, 'c'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal 3
          Thunk.all (
            @zrem 'zsetA', 'a'
          ), (
            @zrem 'zsetA', 'a', 'c'
          ), client.zadd 'zsetA', 1, 'a', 2, 'b', 3, 'c'
      )(
        (error, res) ->
          should(res).be.eql [
            1
            1
            2
          ]
          Thunk.all (
            @zremrangebyrank 'zsetA', 1, 2
          ), @zrange 'zsetA', 0, -1
      )(
        (error, res) ->
          should(res).be.eql [
            2
            ['a']
          ]
          @zadd 'zsetA', 2, 'b', 3, 'c', 4, 'd'
      )(
        (error, res) ->
          should(res).be.equal 3
          Thunk.all (
            @zremrangebyscore 'zsetA', 2, 3
          ), @zrange 'zsetA', 0, -1
      )(
        (error, res) ->
          should(res).be.eql [
            2
            [
              'a'
              'd'
            ]
          ]
          return
      ) done
      return

    it 'client.zrevrange, client.zrevrangebyscore', (done) ->
      Thunk = thunks()

      Thunk.call(
        client, client.zadd 'zsetA', 1, 'a', 2, 'b', 3, 'c'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal 3
          @zrevrange 'zsetA', 1, 100, 'WITHSCORES'
      )(
        (error, res) ->
          should(res).be.eql [
            'b'
            '2'
            'a'
            '1'
          ]
          @zrevrangebyscore 'zsetA', '+inf', '-inf', 'LIMIT', 1, 2
      )(
        (error, res) ->
          should(res).be.eql [
            'b'
            'a'
          ]
          return
      ) done
      return

    it 'client.zunionstore, client.zinterstore', (done) ->
      Thunk = thunks()

      Thunk.call(
        client, client.zadd 'zsetA', 1, 'a', 2, 'b', 3, 'c'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal 3
          client.zadd 'zsetB', 4, 'b', 5, 'c', 6, 'd'
      )(
        (error, res) ->
          should(res).be.equal 3
          @zunionstore 'zsetU', 2, 'zsetA', 'zsetB', 'WEIGHTS', 2, 1, 'AGGREGATE', 'MAX'
      )(
        (error, res) ->
          should(res).be.equal 4
          @zrange 'zsetU', 0, 100, 'WITHSCORES'
      )(
        (error, res) ->
          should(res).be.eql [
            'a'
            '2'
            'b'
            '4'
            'c'
            '6'
            'd'
            '6'
          ]
          @zinterstore 'zsetI', 2, 'zsetA', 'zsetB', 'WEIGHTS', 1, 2
      )(
        (error, res) ->
          should(res).be.equal 2
          @zrange 'zsetI', 0, 100, 'WITHSCORES'
      )(
        (error, res) ->
          should(res).be.eql [
            'b'
            '10'
            'c'
            '13'
          ]
          return
      ) done
      return

    it 'client.zrangebylex, client.zlexcount, client.zremrangebylex', (done) ->
      Thunk = thunks()

      Thunk.call(
        client, client.zadd 'zsetA', 1, 'a', 1, 'b', 1, 'c', 1, 'bc'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal 4
          client.zrangebylex 'zsetA', '[b', '[c'
      )(
        (error, res) ->
          should(res).be.eql [
            'b'
            'bc'
            'c'
          ]
          client.zlexcount 'zsetA', '[b', '[c'
      )(
        (error, res) ->
          should(res).be.equal 3
          client.zremrangebylex 'zsetA', '[b', '[c'
      )(
        (error, res) ->
          should(res).be.equal 3
          client.zrange 'zsetA', 0, 100, 'WITHSCORES'
      )(
        (error, res) ->
          should(res).be.eql [
            'a'
            '1'
          ]
          return
      ) done
      return

    it 'client.zscan', (done) ->
      Thunk = thunks (error) ->
        console.error error
        done error
        return

      count = 100
      data = []
      scanKeys = []

      data.push count, 'z' + count  while count--

      fullScan = (cursor) ->
        client.zscan('zset', cursor) (error, res) ->
          scanKeys = scanKeys.concat res[1]
          return res  if res[0] is '0'
          fullScan res[0]

      client.zscan(
        'zset', 0
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            '0'
            []
          ]
          args = data.slice()
          args.unshift 'zset'
          @zadd.apply @, args
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal 100
          fullScan 0
      )(
        (error, res) ->
          should(scanKeys.length).be.equal 200
          JSONKit.each data, (value) ->
            should(
              scanKeys
            ).be.containEql value + ''
            return
          @zscan 'zset', 0, 'match', '*0', 'COUNT', 200
      )(
        (error, res) ->
          should(
            res[0] is '0'
          ).be.equal true
          should(
            res[1].length is 20
          ).be.equal true
          return
      ) done
      return

    return

  return