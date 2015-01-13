#global describe, it, before, after, beforeEach, afterEach
should = require 'should'
thunks = require 'thunks'
JSONKit = require 'jsonkit'
redis = require '../index'

module.exports = ->

  describe 'commands:Key', ->

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

    it 'client.del, client.exists', (done) ->
      Thunk = thunks (error) ->
        console.error error
        done error
        return

      Thunk.call(
        client, client.mset
          key: 1
          key1: 2
          key2: 3
          key3: 4
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          @exists 'key'
      )(
        (error, res) ->
          should(res).be.equal 1
          @exists 'key1'
      )(
        (error, res) ->
          should(res).be.equal 1
          @exists 'key2'
      )(
        (error, res) ->
          should(res).be.equal 1
          @exists 'key3'
      )(
        (error, res) ->
          should(res).be.equal 1
          @del 'key'
      )(
        (error, res) ->
          should(res).be.equal 1
          @exists 'key'
      )(
        (error, res) ->
          should(res).be.equal 0
          @del 'key1', 'key2', 'key3'
      )(
        (error, res) ->
          should(res).be.equal 3
          @exists 'key1'
      )(
        (error, res) ->
          should(res).be.equal 0
          @exists 'key2'
      )(
        (error, res) ->
          should(res).be.equal 0
          @exists 'key3'
      )(
        (error, res) ->
          should(res).be.equal 0
          @del 'key'
      )(
        (error, res) ->
          should(res).be.equal 0
          return
      ) done
      return

    it 'client.dump, client.restore', (done) ->
      serializedValue = undefined
      Thunk0 = thunks()
      client2 = redis.createClient
        returnBuffers: true
        debugMode: false
      Thunk = thunks (error) ->
        console.error error
        done error
        return

      Thunk.call(
        client2, client2.dump 'dumpKey'
      )(
        (error, res) ->
          should(res).be.equal null
          @set 'dumpKey', 'hello, dump & restore!'
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          @dump 'dumpKey'
      )(
        (error, res) ->
          should(Buffer.isBuffer(res)).be.equal true
          serializedValue = res
          Thunk0.call(
            this, @restore 'restoreKey', 0, 'errorValue'
          ) (error, res) ->
            should(error).be.instanceOf Error
            should(res).be.equal `undefined`
            @restore 'restoreKey', 0, serializedValue
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          @get 'restoreKey'
      )(
        (error, res) ->
          should(
            Buffer.isBuffer res
          ).be.equal true
          should(
            res.toString 'utf8'
          ).be.equal 'hello, dump & restore!'
          Thunk0.call(
            @, @restore 'restoreKey', 0, serializedValue
          ) (error, res) ->
            should(error).be.instanceOf Error
            should(res).be.equal `undefined`
            @get 'restoreKey'
      )(
        (error, res) ->
          should(
            Buffer.isBuffer res
          ).be.equal true
          should(
            res.toString 'utf8'
          ).be.equal 'hello, dump & restore!'
          @restore 'key123', 1000, serializedValue
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          @get 'key123'
      )(
        (error, res) ->
          should(
            Buffer.isBuffer res
          ).be.equal true
          should(
            res.toString 'utf8'
          ).be.equal 'hello, dump & restore!'
          Thunk.delay 1100
      )(
        (error, res) -> @exists 'key123'
      )(
        (error, res) ->
          should(res).be.equal 0
          return
      ) done
      return

    it 'client.expire', (done) ->
      Thunk = thunks (error) ->
        console.error error
        done error
        return

      Thunk.call(
        client, client.set 'key', 123
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          @exists 'key'
      )(
        (error, res) ->
          should(res).be.equal 1
          @expire 'key', 1
      )(
        (error, res) ->
          should(res).be.equal 1
          Thunk.delay.call(
            @, 1010
          ) ->
            @exists 'key'
      )(
        (error, res) ->
          should(res).be.equal 0
          @expire 'key', 1
      )(
        (error, res) ->
          should(res).be.equal 0
          return
      ) done
      return

    it 'client.expireat', (done) ->
      Thunk = thunks (error) ->
        console.error error
        done error
        return
      Thunk.call(
        client, client.set 'key', 123
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          @exists 'key'
      )(
        (error, res) ->
          should(res).be.equal 1
          @expireat 'key', Math.floor(
            Date.now() / 1000 + 1
          )
      )(
        (error, res) ->
          should(res).be.equal 1
          Thunk.delay.call(
            this, 1001
          ) ->
            @exists 'key'
      )(
        (error, res) ->
          should(res).be.equal 0
          @expireat 'key', Math.floor(
            Date.now() / 1000 + 1
          )
      )(
        (error, res) ->
          should(res).be.equal 0
          return
      ) done
      return

    it 'client.keys', (done) ->
      Thunk = thunks (error) ->
        console.error error
        done error
        return
      Thunk.call(
        client, client.keys '*'
      )(
        (error, res) ->
          should(res).be.eql []
          @mset
            a: 123
            a1: 123
            b: 123
            b1: 123
            c: 123
            c1: 123
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          @keys '*'
      )(
        (error, res) ->
          should(
            res.sort()
          ).be.eql [
            'a'
            'a1'
            'b'
            'b1'
            'c'
            'c1'
          ]
          @keys 'a*'
      )(
        (error, res) ->
          should(
            res.sort()
          ).be.eql [
            'a'
            'a1'
          ]
          @keys '?1'
      )(
        (error, res) ->
          should(
            res.sort()
          ).be.eql [
            'a1'
            'b1'
            'c1'
          ]
          return
      ) done
      return

    it 'client.migrate', (done) ->
      Thunk0 = thunks()
      Thunk = thunks (error) ->
        console.error error
        done error
        return
      client2 = redis.createClient 6380

      client2.on 'error', (error) ->
        done()
        return

      Thunk.call(
        client, client.set 'key', 123
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          client2.flushdb()
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          @migrate '127.0.0.1', 6380, 'key', 0, 100
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          @exists 'key'
      )(
        (error, res) ->
          should(res).be.equal 0
          client2.get 'key'
      )(
        (error, res) ->
          should(res).be.equal '123'
          return
      ) done
      return

    it 'client.move', (done) ->
      Thunk0 = thunks()
      Thunk = thunks (error) ->
        console.error error
        done error
        return

      Thunk.call(
        client, client.mset
          key1: 1
          key2: 2
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          @select 1
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          @mset
            key2: 4
            key3: 6
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          @move 'key2', 0
      )(
        (error, res) ->
          should(res).be.equal 0
          @get 'key2'
      )(
        (error, res) ->
          should(res).be.equal '4'
          @move 'key3', 0
      )(
        (error, res) ->
          should(res).be.equal 1
          @exists 'key3'
      )(
        (error, res) ->
          should(res).be.equal 0
          @move 'key4', 0
      )(
        (error, res) ->
          should(res).be.equal 0
          @select 0
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          @get 'key3'
      )(
        (error, res) ->
          should(res).be.equal '6'
          @get 'key2'
      )(
        (error, res) ->
          should(res).be.equal '2'
          Thunk0(
            @move 'key2', 0
          ) (error, res) ->
            should(error).be.instanceOf Error
            return
      ) done
      return

    it 'client.object', (done) ->
      Thunk = thunks (error) ->
        console.error error
        done error
        return
      Thunk.call(
        client, client.mset
          key1: 123
          key2: 'hello'
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          @object 'refcount', 'key1'
      )(
        (error, res) ->
          should(
            res >= 1
          ).be.equal true
          @object 'encoding', 'key1'
      )(
        (error, res) ->
          should(res).be.equal 'int'
          @object 'encoding', 'key2'
      )(
        (error, res) ->
          should(res).be.equal 'raw'
          Thunk.delay 1001
      )(
        (error, res) ->
          @object 'idletime', 'key1'
      )(
        (error, res) ->
          should(
            res >= 1
          ).be.equal true
          return
      ) done
      return

    it 'client.persist', (done) ->
      Thunk = thunks (error) ->
        console.error error
        done error
        return

      Thunk.call(
        client, client.set 'key', 'hello'
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          @expire 'key', 1
      )(
        (error, res) ->
          should(res).be.equal 1
          @persist 'key'
      )(
        (error, res) ->
          should(res).be.equal 1
          @persist 'key'
      )(
        (error, res) ->
          should(res).be.equal 0
          Thunk.delay 1001
      )(
        (error, res) ->
          @exists 'key'
      )(
        (error, res) ->
          should(res).be.equal 1
          @persist 'key123'
      )(
        (error, res) ->
          should(res).be.equal 0
          return
      ) done
      return

    it 'client.pexpire', (done) ->
      Thunk = thunks (error) ->
        console.error error
        done error
        return

      Thunk.call(
        client, client.set 'key', 123
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          @exists 'key'
      )(
        (error, res) ->
          should(res).be.equal 1
          @pexpire 'key', 100
      )(
        (error, res) ->
          should(res).be.equal 1
          Thunk.delay.call(
            @, 101
          ) ->
            @exists 'key'
      )(
        (error, res) ->
          should(res).be.equal 0
          @pexpire 'key', 100
      )(
        (error, res) ->
          should(res).be.equal 0
          return
      ) done
      return

    it 'client.pexpireat', (done) ->
      Thunk = thunks (error) ->
        console.error error
        done error
        return

      Thunk.call(
        client, client.set 'key', 123
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          @exists 'key'
      )(
        (error, res) ->
          should(res).be.equal 1
          @pexpireat 'key', Date.now() + 100
      )(
        (error, res) ->
          should(res).be.equal 1
          Thunk.delay.call(
            @, 101
          ) ->
            @exists 'key'
      )(
        (error, res) ->
          should(res).be.equal 0
          @pexpireat 'key', Date.now() + 100
      )(
        (error, res) ->
          should(res).be.equal 0
          return
      ) done
      return

    it 'client.pttl, client.ttl', (done) ->
      Thunk = thunks (error) ->
        console.error error
        done error
        return

      Thunk.call(
        client, client.set 'key', 'hello'
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          @pttl 'key'
      )(
        (error, res) ->
          should(res).be.equal -1
          @pttl 'key123'
      )(
        (error, res) ->
          should(res).be.equal -2
          @ttl 'key'
      )(
        (error, res) ->
          should(res).be.equal -1
          @ttl 'key123'
      )(
        (error, res) ->
          should(res).be.equal -2
          @exists 'key'
      )(
        (error, res) ->
          should(res).be.equal 1
          @pexpire 'key', 1200
      )(
        (error, res) ->
          should(res).be.equal 1
          @ttl 'key'
      )(
        (error, res) ->
          should(
            res >= 1
          ).be.equal true
          @pttl 'key'
      )(
        (error, res) ->
          should(
            res >= 1000
          ).be.equal true
          return
      ) done
      return

    it 'client.randomkey', (done) ->
      Thunk = thunks (error) ->
        console.error error
        done error
        return

      Thunk.call(
        client, client.randomkey()
      )(
        (error, res) ->
          should(res).be.equal null
          @set 'key', 'hello'
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          @randomkey()
      )(
        (error, res) ->
          should(res).be.equal 'key'
          return
      ) done
      return

    it 'client.rename, client.renamenx', (done) ->
      Thunk0 = thunks()
      Thunk = thunks (error) ->
        console.error error
        done error
        return

      Thunk.call(
        client, client.mset
          key: 'hello'
          newkey: 1
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          @rename 'key', 'newkey'
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          @exists 'key'
      )(
        (error, res) ->
          should(res).be.equal 0
          @get 'newkey'
      )(
        (error, res) ->
          should(res).be.equal 'hello'
          Thunk0.call(
            @, @rename 'key', 'key1'
          )(
            (error, res) ->
              should(error).be.instanceOf Error
              @rename 'newkey', 'newkey'
          )(
            (error, res) ->
              should(error).be.instanceOf Error
              @renamenx 'key', 'newkey'
          ) (error, res) ->
            should(error).be.instanceOf Error
            @set 'key', 1
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          @renamenx 'newkey', 'key'
      )(
        (error, res) ->
          should(res).be.equal 0
          @renamenx 'newkey', 'key1'
      )(
        (error, res) ->
          should(res).be.equal 1
          @get 'key1'
      )(
        (error, res) ->
          should(res).be.equal 'hello'
          @exists 'newkey'
      )(
        (error, res) ->
          should(res).be.equal 0
          return
      ) done
      return

    it 'client.sort', (done) ->
      Thunk0 = thunks()
      Thunk = thunks (error) ->
        console.error error
        done error
        return

      Thunk.call(
        client, client.sort 'key'
      )(
        (error, res) ->
          should(res).be.eql []
          @set 'key', 12345
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          Thunk0.call(
            @, @sort 'key'
          ) (error, res) ->
            should(error).be.instanceOf Error
            @lpush 'list', 1, 3, 5, 4, 2
      )(
        (error, res) ->
          should(res).be.equal 5
          @sort 'list'
      )(
        (error, res) ->
          should(res).be.eql [
            '1'
            '2'
            '3'
            '4'
            '5'
          ]
          @sort 'list', 'desc'
      )(
        (error, res) ->
          should(res).be.eql [
            '5'
            '4'
            '3'
            '2'
            '1'
          ]
          @lpush 'list1', 'a', 'b', 'ac'
      )(
        (error, res) ->
          should(res).be.equal 3
          @sort 'list1', 'desc', 'alpha'
      )(
        (error, res) ->
          should(res).be.eql [
            'b'
            'ac'
            'a'
          ]
          @sort 'list', 'desc', 'limit', '1', '3'
      )(
        (error, res) ->
          should(res).be.eql [
            '4'
            '3'
            '2'
          ]
          @mset
            user1: 80
            user2: 100
            user3: 90
            user4: 70
            user5: 95
            user1name: 'zhang'
            user2name: 'li'
            user3name: 'wang'
            user4name: 'liu'
            user5name: 'yan'
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          @sort 'list', 'by', 'user*', 'get', 'user*name', 'desc'
      )(
        (error, res) ->
          should(res).be.eql [
            'li'
            'yan'
            'wang'
            'zhang'
            'liu'
          ]
          @sort 'list', 'by', 'user*', 'get', 'user*name', 'store', 'sorteduser'
      )(
        (error, res) ->
          should(res).be.equal 5
          @lrange 'sorteduser', 0, -1
      )(
        (error, res) ->
          should(res).be.eql [
            'liu'
            'zhang'
            'wang'
            'yan'
            'li'
          ]
          return
      ) done
      return

    it 'client.type', (done) ->
      Thunk = thunks (error) ->
        console.error error
        done error
        return
      Thunk.call(
        client, client.mset
          a: 123
          b: '123'
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          @type 'key'
      )(
        (error, res) ->
          should(res).be.equal 'none'
          @type 'a'
      )(
        (error, res) ->
          should(res).be.equal 'string'
          @type 'b'
      )(
        (error, res) ->
          should(res).be.equal 'string'
          @lpush 'list', '123'
      )(
        (error, res) ->
          should(res).be.equal 1
          @type 'list'
      )(
        (error, res) ->
          should(res).be.equal 'list'
          return
      ) done
      return

    it 'client.scan', (done) ->

      Thunk = thunks (error) ->
        console.error error
        done error
        return

      count = 100
      data = {}
      scanKeys = []

      data['key' + count] = count  while count--

      fullScan = (cursor) ->
        client.scan(
          cursor
        ) (error, res) ->
          scanKeys = scanKeys.concat res[1]
          return res  if res[0] is '0'
          fullScan res[0]

      Thunk.call(
        client, client.scan 0
      )(
        (error, res) ->
          should(res).be.eql [
            '0'
            []
          ]
          @mset data
      )(
        (error, res) ->
          should(res).be.equal 'OK'
          fullScan 0
      )(
        (error, res) ->
          JSONKit.each data, (value, key) ->
            should(
              scanKeys.indexOf(key) >= 0
            ).be.equal true
            return
          @scan '0', 'count', 20
      )(
        (error, res) ->
          should(
            res[0] > 0
          ).be.equal true
          should(
            res[1].length > 0
          ).be.equal true
          @scan '0', 'count', 200, 'match', '*0'
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