#global describe, it, before, after, beforeEach, afterEach
should = require 'should'
thunks = require 'thunks'
redis = require '../index'

module.exports = ->

  describe 'commands:String', ->

    client = undefined

    before ->
      client = redis.createClient database: 0
      client.on 'error', (error) ->
        console.error 'redis client:', error
        return

      return

    beforeEach (done) ->
      client.flushdb()((error, res) ->
        should(error).be.equal null
        should(res).be.equal 'OK'
        return
      ) done
      return

    after ->
      client.clientEnd()
      return

    it 'client.append', (done) ->
      Thunk = thunks((error) ->
        console.error error
        done error
        return
      )
      Thunk.call(
        client, client.append 'key', 123
      )(
        (error, res) ->
          should(res).be.equal 3
          @append 'key', 456
      )(
        (error, res) ->
          should(res).be.equal 6
          @get 'key'
      )(
        (error, res) ->
          should(res).be.equal '123456'
          return
      ) done
      return

    it 'client.bitcount, client.getbit, client.setbit', (done) ->
      Thunk = thunks (error) ->
        console.error error
        done error
        return

      Thunk.call(
        client, client.getbit 'key', 9
      )(
        (error, res) ->
          should(res).be.equal 0
          @setbit 'key', 9, 1
      )(
        (error, res) ->
          should(res).be.equal 0
          @getbit 'key', 9
      )(
        (error, res) ->
          should(res).be.equal 1
          @setbit 'key', 9, 0
      )(
        (error, res) ->
          should(res).be.equal 1
          @bitcount 'key', 1, 2
      )(
        (error, res) ->
          should(res).be.equal 0
          @del 'key'
      )(
        (error, res) ->
          should(res).be.equal 1
          @bitcount 'key'
      )(
        (error, res) ->
          should(res).be.equal 0
          @setbit 'key', 0, 1
      )(
        (error, res) ->
          should(res).be.equal 0
          @setbit 'key', 3, 1
      )(
        (error, res) ->
          should(res).be.equal 0
          @bitcount 'key'
      )(
        (error, res) ->
          should(res).be.equal 2
          @bitcount 'key', 1, 2
      )(
        (error, res) ->
          should(res).be.equal 0
          return
      ) done
      return

    it 'client.bitop', (done) ->
      Thunk = thunks((error) ->
        console.error error
        done error
        return
      )
      Thunk.call(
        client, client.bitop 'or', 'key', 'key1', 'key2', 'key3'
      )(
        (error, res) ->
          should(res).be.equal 0
          @setbit 'key1', 0, 1
      )(
        (error, res) ->
          should(res).be.equal 0
          @setbit 'key2', 1, 1
      )(
        (error, res) ->
          should(res).be.equal 0
          @setbit 'key3', 2, 1
      )(
        (error, res) ->
          should(res).be.equal 0
          @bitop 'or', 'key', 'key1', 'key2', 'key3'
      )(
        (error, res) ->
          should(res).be.equal 1
          @getbit 'key', 2
      )(
        (error, res) ->
          should(res).be.equal 1
          @bitop 'and', 'key', 'key1', 'key2', 'key3'
      )(
        (error, res) ->
          should(res).be.equal 1
          @bitop 'xor', 'key', 'key1', 'key2', 'key3'
      )(
        (error, res) ->
          should(res).be.equal 1
          @bitop 'not', 'key', 'key1'
      )(
        (error, res) ->
          should(res).be.equal 1
          return
      ) done
      return

    it 'client.bitpos', (done) ->
      Thunk = thunks (error) ->
        console.error error
        done error
        return

      Thunk.call(
        client, client.set 'key', 'ÿð\u0000'
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          @bitpos 'key', 0
      )(
        (error, res) ->
          should(res).be.equal 2
          @set 'key2', '\u0000ÿð'
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          @bitpos 'key2', 1, 0
      )(
        (error, res) ->
          should(res).be.equal 8
          @bitpos 'key2', 1, 2
      )(
        (error, res) ->
          should(res).be.equal 16
          @set 'key3', '\u0000\u0000\u0000'
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          @bitpos 'key3', 1
      )(
        (error, res) ->
          should(res).be.equal -1
          return
      ) done
      return

    it 'client.decr, client.decrby, client.incr, client.incrby, client.incrbyfloat', (done) ->
      Thunk0 = thunks()
      Thunk = thunks (error) ->
        console.error error
        done error
        return

      Thunk.call(
        client, client.decr 'key'
      )(
        (error, res) ->
          should(res).be.equal -1
          @decrby 'key', 9
      )(
        (error, res) ->
          should(res).be.equal -10
          @incr 'key'
      )(
        (error, res) ->
          should(res).be.equal -9
          @incrby 'key', 10
      )(
        (error, res) ->
          should(res).be.equal 1
          @incrbyfloat 'key', 1.1
      )(
        (error, res) ->
          should(res).be.equal '2.1'
          Thunk0.call(this, @incr('key')) (error, res) ->
            should(error).be.instanceOf Error
            return
      ) done
      return

    it 'client.get, client.set', (done) ->
      Thunk0 = thunks()
      Thunk = thunks (error) ->
        console.error error
        done error
        return

      Thunk.call(
        client, client.get 'key'
      )(
        (error, res) ->
          should(res).be.equal null
          @lpush 'key', 'hello'
      )(
        (error, res) ->
          should(res).be.equal 1
          Thunk0.call(
            @, @get 'key'
          ) (error, res) ->
            should(error).be.instanceOf Error
            @set 'key', 'hello'
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          @get 'key'
      )(
        (error, res) ->
          should(res).be.equal 'hello'
          @set 'key', 123, 'nx'
      )(
        (error, res) ->
          should(res).be.equal null
          @set 'key1', 123, 'xx'
      )(
        (error, res) ->
          should(res).be.equal null
          @set 'key1', 123, 'nx', 'ex', 1
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          @set 'key1', 456, 'xx', 'px', 1100
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          @pttl 'key1'
      )(
        (error, res) ->
          should(
            res > 1000
          ).be.equal true
          return
      ) done
      return

    it 'client.getset, client.getrange', (done) ->
      Thunk0 = thunks()
      Thunk = thunks (error) ->
        console.error error
        done error
        return

      Thunk.call(
        client, client.getset 'key', 'hello'
      )(
        (error, res) ->
          should(res).be.equal null
          @getrange 'key', 0, -2
      )(
        (error, res) ->
          should(res).be.equal 'hell'
          @getset 'key', 'world'
      )(
        (error, res) ->
          should(res).be.equal 'hello'
          @getrange 'key', 1, 2
      )(
        (error, res) ->
          should(res).be.equal 'or'
          @lpush 'key1', 'hello'
      )(
        (error, res) ->
          should(res).be.equal 1
          Thunk0.call(
            @, @getset 'key1', 'world'
          )(
            (error, res) ->
              should(error).be.instanceOf Error
              @getrange 'key1', 0, 10086
          ) (error, res) ->
            should(error).be.instanceOf Error
            return
      ) done
      return

    it 'client.mget, client.mset, client.msetnx', (done) ->
      Thunk = thunks (error) ->
        console.error error
        done error
        return

      Thunk.call(
        client, client.mget 'key1', 'key2'
      )(
        (error, res) ->
          should(res).be.eql [
            null
            null
          ]
          @mset 'key1', 1, 'key2', 2
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          @mget 'key1', 'key3', 'key2'
      )(
        (error, res) ->
          should(res).be.eql [
            '1'
            null
            '2'
          ]
          @mset
            key1: 0
            key3: 3
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          @mget 'key1', 'key3', 'key2'
      )(
        (error, res) ->
          should(res).be.eql [
            '0'
            '3'
            '2'
          ]
          @msetnx 'key3', 1, 'key4', 4
      )(
        (error, res) ->
          should(res).be.equal 0
          @exists 'key4'
      )(
        (error, res) ->
          should(res).be.equal 0
          @msetnx 'key4', 4, 'key5', 5
      )(
        (error, res) ->
          should(res).be.equal 1
          @msetnx
            key6: 6
            key: 0
      )(
        (error, res) ->
          should(res).be.equal 1
          @mget 'key', 'key5', 'key6'
      )(
        (error, res) ->
          should(res).be.eql [
            '0'
            '5'
            '6'
          ]
          return
      ) done
      return

    it 'client.psetex, client.setex, client.setnx, client.setrange, client.strlen', (done) ->
      Thunk0 = thunks()
      Thunk = thunks (error) ->
        console.error error
        done error
        return

      Thunk.call(
        client, client.strlen 'key'
      )(
        (error, res) ->
          should(res).be.equal 0
          @lpush 'key', 'hello'
      )(
        (error, res) ->
          should(res).be.equal 1
          Thunk0.call(this, @strlen('key')) (error, res) ->
            should(error).be.instanceOf Error
            @setnx 'key', 'hello'
      )(
        (error, res) ->
          should(res).be.equal 0
          @setnx 'key1', 'hello'
      )(
        (error, res) ->
          should(res).be.equal 1
          @setnx 'key1', 123
      )(
        (error, res) ->
          should(res).be.equal 0
          @setex 'key1', 1, 456
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          @psetex 'key1', 1100, 789
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          @pttl 'key1'
      )(
        (error, res) ->
          should(res > 1000).be.equal true
          @get 'key1'
      )(
        (error, res) ->
          should(res).be.equal '789'
          @setrange 'key1', 3, '012'
      )(
        (error, res) ->
          should(res).be.equal 6
          @get 'key1'
      )(
        (error, res) ->
          should(res).be.equal '789012'
          @setrange 'key2', 10, 'hello'
      )(
        (error, res) ->
          should(res).be.equal 15
          @get 'key2'
      )(
        (error, res) ->
          should(res).be.endWith 'hello'
          return
      ) done
      return

    return

  return