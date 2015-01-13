#global describe, it, before, after, beforeEach, afterEach
should = require 'should'
thunks = require 'thunks'
redis = require '../index'

module.exports = ->

  describe 'commands:List', ->
    client = client1 = undefined

    before ->

      client = redis.createClient
        database: 0
        debugMode: false

      client.on 'error', (error) ->
        console.error 'redis client:', error
        return

      client1 = redis.createClient
        database: 0
        debugMode: false

      client1.on 'error', (error) ->
        console.error 'redis client1:', error
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
      client1.clientEnd()
      return

    it 'client.blpop, client.brpop', (done) ->
      Thunk = thunks()
      time = Date.now()
      Thunk.all.call(
        client, [
          client.blpop 'listA', 0
          Thunk.delay(100) ->
            client1.lpush 'listA', 'abc'
        ]
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            [
              'listA'
              'abc'
            ]
            1
          ]
          should(
            (Date.now() - time) > 100
          ).be.equal true
          Thunk.all (
            @blpop 'listA', 0
          ), (
            client1.lpush 'listA', 'abcd'
          ), @llen 'listA'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            [
              'listA'
              'abcd'
            ]
            1
            0
          ]
          Thunk.all (
            @lpush 'listB', 'b', 'b1'
          ), (
            @lpush 'listC', 'c'
          ), (
            @blpop 'listA', 'listB', 'listC', 0
          ), @llen 'listB'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            2
            1
            [
              'listB'
              'b1'
            ]
            1
          ]
          Thunk.all (
            @lpush 'listD', 'd', 'd1'
          ), (
            @lpush 'listC', 'c'
          ), (
            @brpop 'listA', 'listD', 'listC', 0
          ), @llen 'listB'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            2
            2
            [
              'listD'
              'd'
            ]
            1
          ]
          return
      ) done
      return

    it 'client.brpoplpush, client.rpoplpush', (done) ->
      Thunk = thunks()
      time = Date.now()
      Thunk.all.call(
        client, [
          client.brpoplpush 'listA', 'listB', 0
          Thunk.delay(100) ->
            client1.lpush 'listA', 'abc'
        ]
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            'abc'
            1
          ]
          should(
            (Date.now() - time) > 100
          ).be.equal true
          Thunk.all (
            @lpush 'listB', 'b0', 'b1'
          ), (
            @rpoplpush 'listA', 'listB'
          ), @llen 'listB'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            3
            null
            3
          ]
          Thunk.all (
            @lpush 'listA', 'a0', 'a1'
          ), (
            @rpoplpush 'listA', 'listB'
          ), @lrange 'listB', 0, -1
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            2
            'a0'
            [
              'a0'
              'b1'
              'b0'
              'abc'
            ]
          ]
          Thunk.all (
            @rpoplpush 'listB', 'listB'
          ), @lrange 'listB', 0, -1
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            'abc'
            [
              'abc'
              'a0'
              'b1'
              'b0'
            ]
          ]
          return
      ) done
      return

    it 'client.lindex, client.linsert', (done) ->
      Thunk = thunks()
      Thunk.call(
        client, client.lindex 'listA', 0
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal null
          Thunk.all (
            @lpush 'listA', 'a0', 'a1'
          ), (
            @lindex 'listA', 0
          ), @lindex 'listA', -1
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            2
            'a1'
            'a0'
          ]
          Thunk.all (
            @set 'key', 123
          ), @lindex 'key', 0
      )(
        (error, res) ->
          should(error).be.instanceOf Error
          @linsert 'key', 'before', 'abc', 'edf'
      )(
        (error, res) ->
          should(error).be.instanceOf Error
          @linsert 'listB', 'before', 'abc', 'edf'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal 0
          @linsert 'listA', 'before', 'abc', 'edf'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal -1
          Thunk.all (
            @linsert 'listA', 'before', 'a0', 'edf'
          ), (
            @linsert 'listA', 'after', 'a0', 'edf'
          ), @lrange 'listA', 0, -1
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            3
            4
            [
              'a1'
              'edf'
              'a0'
              'edf'
            ]
          ]
          return
      ) done
      return

    it 'client.llen, client.lpop, client.lpush', (done) ->
      Thunk = thunks()
      Thunk.call(
        client, client.llen 'listA'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal 0
          Thunk.all (
            @set 'key', 123
          ), @llen 'key'
      )(
        (error, res) ->
          should(error).be.instanceOf Error
          Thunk.all (
            @lpush 'listA', 'a0', 'a1', 'a2'
          ), @llen 'listA'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            3
            3
          ]
          Thunk.all (
            @lpop 'listA'
          ), (
            @lpop 'listA'
          ), (
            @lpop 'listA'
          ), @lpop 'listA'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            'a2'
            'a1'
            'a0'
            null
          ]
          return
      ) done
      return

    it 'client.lpushx, client.lrange, client.lrem', (done) ->
      Thunk = thunks()
      Thunk.call(
        client, client.lpushx 'listA', 'a'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal 0
          Thunk.all (
            @set 'key', 123
          ), @lpushx 'key', 'a'
      )(
        (error, res) ->
          should(error).be.instanceOf Error
          Thunk.all (
            @lpush 'listA', 'a0'
          ), @lpushx 'listA', 'a1'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            1
            2
          ]
          Thunk.all (
            @lrange 'listA', 0, -1
          ), @lrange 'listB', 0, -1
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            [
              'a1'
              'a0'
            ]
            []
          ]
          Thunk.all (
            @lrem 'listA', 0, 'a0'
          ), @lrem 'listB', 0, 'a0'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            1
            0
          ]
          Thunk.all (
            @lpush 'listB', 'b0', 'b1', 'b', 'b1', 'b2'
          ), (
            @lrem 'listB', 0, 'b1'
          ), @lrange 'listB', 0, -1
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            5
            2
            [
              'b2'
              'b'
              'b0'
            ]
          ]
          return
      ) done
      return

    it 'client.lset, client.ltrim', (done) ->
      Thunk = thunks()
      Thunk.call(
        client, client.lset 'listA', 0, 'a'
      )(
        (error, res) ->
          should(error).be.instanceOf Error
          Thunk.all (
            @lpush 'listA', 'a'
          ), @lset 'listA', 1, 'a'
      )(
        (error, res) ->
          should(error).be.instanceOf Error
          Thunk.all (
            @lpush 'listA', 'b'
          ), (
            @lset 'listA', 1, 'a1'
          )
          , @lrange 'listA', 0, -1
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            2
            'OK'
            [
              'b'
              'a1'
            ]
          ]
          Thunk.all (
            @ltrim 'listA', 0, 0
          ), (
            @ltrim 'listB', 0, 0
          ), @lrange 'listA', 0, -1
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            'OK'
            'OK'
            ['b']
          ]
          Thunk.all (
            @set 'key', 'a'
          ), @ltrim 'key', 0, 0
      )(
        (error, res) ->
          should(error).be.instanceOf Error
          return
      ) done
      return

    it 'client.rpop, client.rpush, client.rpushx', (done) ->
      Thunk = thunks()
      Thunk.call(
        client, client.rpop 'listA'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal null
          Thunk.all (
            @set 'key', 123
          ), @rpop 'key'
      )(
        (error, res) ->
          should(error).be.instanceOf Error
          Thunk.all (
            @rpush 'listA', 'a0', 'a1', 'a2'
          ), @rpop 'listA'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            3
            'a2'
          ]
          Thunk.all (
            @rpushx 'listA', 'a3'
          ), @rpushx 'listB', 'a3'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            3
            0
          ]
          return
      ) done
      return

    return

  return