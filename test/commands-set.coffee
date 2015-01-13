#global describe, it, before, after, beforeEach, afterEach
should = require 'should'
thunks = require 'thunks'
JSONKit = require 'jsonkit'
redis = require '../index'

module.exports = ->

  describe 'commands:Set', ->

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

    it 'client.sadd, client.scard', (done) ->
      Thunk = thunks()
      Thunk.call(
        client, client.scard 'setA'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal 0
          Thunk.all (
            @set 'key', 'abc'
          ), @scard 'key'
      )(
        (error, res) ->
          should(error).be.instanceOf Error
          @sadd 'key', 'a'
      )(
        (error, res) ->
          should(error).be.instanceOf Error
          Thunk.all (
            @sadd 'setA', 'a', 'b'
          ), (
            @sadd 'setA', 'b', 'c'
          ), (
            @sadd 'setA', 'a', 'c'
          ), @scard 'setA'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            2
            1
            0
            3
          ]
          return
      ) done
      return

    it 'client.sdiff, client.sdiffstore', (done) ->
      Thunk = thunks()
      Thunk.call(
        client, client.sdiff 'setA'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql []
          Thunk.all (
            @sadd 'setA', 'a', 'b', 'c'
          ), @sadd 'setB', 'b', 'c', 'd'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            3
            3
          ]
          Thunk.all (
            client.sdiff 'setA'
          ), (
            client.sdiff 'setA', 'setB'
          ), client.sdiff 'setA', 'setC'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res[0].length).be.equal 3
          should(res[0]).be.containEql 'a'
          should(res[0]).be.containEql 'b'
          should(res[0]).be.containEql 'c'
          should(res[1].length).be.equal 1
          should(res[1]).be.containEql 'a'
          should(res[2].length).be.equal 3
          should(res[2]).be.containEql 'a'
          should(res[2]).be.containEql 'b'
          should(res[2]).be.containEql 'c'
          Thunk.all (
            client.sdiffstore 'setC', 'setA', 'setB'
          ), client.sdiffstore 'setA', 'setA', 'setB'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            1
            1
          ]
          Thunk.all (
            @scard 'setA'
          ), @scard 'setC'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            1
            1
          ]
          return
      ) done
      return

    it 'client.sinter, client.sinterstore', (done) ->
      Thunk = thunks()
      Thunk.call(
        client, client.sinter 'setA'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql []
          Thunk.all (
            @sadd 'setA', 'a', 'b', 'c'
          ), @sadd 'setB', 'b', 'c', 'd'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            3
            3
          ]
          Thunk.all (
            client.sinter 'setA'
          ), (
            client.sinter 'setA', 'setB'
          ), client.sinter 'setA', 'setC'
      )(
        (error, res) ->
          should(error).be.equal null
          should(
            res[0].length
          ).be.equal 3
          should(
            res[0]
          ).be.containEql 'a'
          should(
            res[0]
          ).be.containEql 'b'
          should(
            res[0]
          ).be.containEql 'c'
          should(
            res[1].length
          ).be.equal 2
          should(
            res[1]
          ).be.containEql 'b'
          should(
            res[1]
          ).be.containEql 'c'
          should(
            res[2].length
          ).be.equal 0
          Thunk.all (
            client.sinterstore 'setC', 'setA', 'setB'
          ), client.sinterstore 'setA', 'setA', 'setB'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            2
            2
          ]
          Thunk.all (
            @scard 'setA'
          ), @scard 'setC'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            2
            2
          ]
          return
      ) done
      return

    it 'client.sismember, client.smembers', (done) ->
      Thunk = thunks()
      Thunk.call(
        client, client.smembers 'setA'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal []
          Thunk.all (
            @set 'key', 'abc'
          ), @smembers 'key'
      )(
        (error, res) ->
          should(error).be.instanceOf Error
          Thunk.all (
            @sadd 'setA', 'a', 'b', 'c'
          ), @smembers 'setA'
      )(
        (error, res) ->
          should(error).be.equal null
          should(
            res[0]
          ).be.equal 3
          should(
            res[1].length
          ).be.equal 3
          should(
            res[1]
          ).be.containEql 'a'
          should(
            res[1]
          ).be.containEql 'b'
          should(
            res[1]
          ).be.containEql 'c'
          Thunk.all (
            @sismember 'setA', 'a'
          ), (
            @sismember 'setA', 'd'
          ), @sismember 'setB', 'd'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            1
            0
            0
          ]
          return
      ) done
      return

    it 'client.smove, client.spop', (done) ->
      Thunk = thunks()
      Thunk.call(
        client, client.smove 'setA', 'setB', 'a'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal 0
          Thunk.all (
            @sadd 'setA', 'a', 'b', 'c'
          ), (
            @smove 'setA', 'setB', 'a'
          ), @smove 'setA', 'setB', 'd'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            3
            1
            0
          ]
          Thunk.all (
            @sadd 'setB', 'b'
          ), @smove 'setA', 'setB', 'b'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            1
            1
          ]
          Thunk.all (
            @spop 'setA'
          ), @spop 'setC'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            'c'
            null
          ]
          return
      ) done
      return

    it 'client.srandmember, client.srem', (done) ->
      Thunk = thunks()
      Thunk.call(
        client, client.srandmember 'setA'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal null
          Thunk.all (
            @sadd 'setA', 'a', 'b', 'c'
          ), (
            @srandmember 'setA'
          ), @srandmember 'setA', 2
      )(
        (error, res) ->
          should(error).be.equal null
          should(
            res[0]
          ).be.eql 3
          should(
            [
              'a'
              'b'
              'c'
            ]
          ).be.containEql res[1]
          should(
            res[2].length
          ).be.equal 2
          should(
            [
              'a'
              'b'
              'c'
            ]
          ).be.containEql res[2][0]
          should(
            [
              'a'
              'b'
              'c'
            ]
          ).be.containEql res[2][1]
          Thunk.all (
            @scard 'setA'
          ), (
            @srem 'setA', 'b', 'd'
          ), (
            @srem 'setA', 'b', 'a', 'c'
          ), @scard 'setA'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            3
            1
            2
            0
          ]
          return
      ) done
      return

    it 'client.sunion, client.sunionstore', (done) ->
      Thunk = thunks()
      Thunk.call(
        client, client.sunion 'setA'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql []
          Thunk.all (
            @sadd 'setA', 'a', 'b', 'c'
          ), @sadd 'setB', 'b', 'c', 'd'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            3
            3
          ]
          Thunk.all (
            client.sunion 'setA'
          ), (
            client.sunion 'setA', 'setB'
          ), client.sunion 'setA', 'setC'
      )(
        (error, res) ->
          should(error).be.equal null
          should(
            res[0].length
          ).be.equal 3
          should(
            res[0]
          ).be.containEql 'a'
          should(
            res[0]
          ).be.containEql 'b'
          should(
            res[0]
          ).be.containEql 'c'
          should(
            res[1].length
          ).be.equal 4
          should(
            res[1]
          ).be.containEql 'a'
          should(
            res[1]
          ).be.containEql 'b'
          should(
            res[1]
          ).be.containEql 'c'
          should(
            res[1]
          ).be.containEql 'd'
          should(
            res[2].length
          ).be.equal 3
          Thunk.all (
            client.sunionstore 'setC', 'setA', 'setB'
          ), client.sunionstore 'setA', 'setA', 'setB'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            4
            4
          ]
          Thunk.all (
            @scard 'setA'
          ), @scard 'setC'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            4
            4
          ]
          return
      ) done
      return

    it 'client.sscan', (done) ->

      Thunk = thunks (error) ->
        console.error error
        done error
        return

      count = 100
      data = []
      scanKeys = []

      data.push 'm' + count  while count--

      fullScan = (cursor) ->
        client.sscan(
          'set', cursor
        ) (error, res) ->
          scanKeys = scanKeys.concat res[1]
          return res  if res[0] is '0'
          fullScan res[0]

      Thunk.call(
        client, client.sscan 'set', 0
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            '0'
            []
          ]
          args = data.slice()
          args.unshift 'set'
          @sadd.apply this, args
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal 100
          fullScan 0
      )(
        (error, res) ->
          should(
            scanKeys.length
          ).be.equal 100
          JSONKit.each data, (value) ->
            should(
              scanKeys
            ).be.containEql value
            return
          @sscan 'set', 0, 'count', 20
      )(
        (error, res) ->
          should(
            res[0] > 0
          ).be.equal true
          should(
            res[1].length > 0
          ).be.equal true
          @sscan 'set', 0, 'count', 200, 'match', '*0'
      )(
        (error, res) ->
          should(
            res[0] is '0'
          ).be.equal true
          should(
            res[1].length is 10
          ).be.equal true
          return
      ) done
      return

    return

  return