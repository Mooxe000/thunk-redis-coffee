#global describe, it, before, after, beforeEach, afterEach
should = require 'should'
thunks = require 'thunks'
redis = require '../index'

module.exports = ->

  describe 'commands:Pubsub', ->
    client1 = client2 = client3 = undefined

    beforeEach (done) ->
      client1 = redis.createClient debugMode: false
      client1.on 'error', (error) ->
        console.error 'redis client:', error
        return

      client2 = redis.createClient debugMode: false
      client2.on 'error', (error) ->
        console.error 'redis client:', error
        return

      client3 = redis.createClient debugMode: false
      client3.on 'error', (error) ->
        console.error 'redis client:', error
        return

      client1.flushdb()(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal 'OK'
          return
      ) done
      return

    afterEach ->
      client1.clientEnd()
      client2.clientEnd()
      client3.clientEnd()
      return

    it 'client.psubscribe, client.punsubscribe', (done) ->
      client1

      .on 'psubscribe', (pattern, n) ->
        should(n).be.equal 1  if pattern is 'a.*'
        should(n).be.equal 2  if pattern is 'b.*'
        should(n).be.equal 3  if pattern is '123'
        return

      .on 'punsubscribe', (pattern, n) ->
        should(n).be.equal 2  if pattern is 'a.*'
        should(n).be.equal 1  if pattern is 'b.*'
        if pattern is '123'
          should(n).be.equal 0
          done()
        return

      client1.psubscribe() (error, res) ->
        should(error).be.instanceOf Error
        should(res).be.equal `undefined`
        return

      client1.psubscribe(
        'a.*', 'b.*', '123'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal `undefined`
          @punsubscribe()
      ) (error, res) ->
        should(error).be.equal null
        should(res).be.equal `undefined`
        return

      return

    it 'client.subscribe, client.unsubscribe', (done) ->
      client1

      .on 'subscribe', (pattern, n) ->
        should(n).be.equal 1  if pattern is 'a'
        should(n).be.equal 2  if pattern is 'b'
        should(n).be.equal 3  if pattern is '123'
        return

      .on 'unsubscribe', (pattern, n) ->
        should(n).be.equal 2  if pattern is 'a'
        should(n).be.equal 2  if pattern is '*'
        should(n).be.equal 1  if pattern is '123'
        if pattern is 'b'
          should(n).be.equal 0
          done()
        return

      client1.subscribe() (error, res) ->
        should(error).be.instanceOf Error
        should(res).be.equal `undefined`
        return

      client1.subscribe(
        'a', 'b', '123'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal `undefined`
          @unsubscribe 'a', '*', '123', 'b'
      ) (error, res) ->
        should(error).be.equal null
        should(res).be.equal `undefined`
        return

      return

    it 'client.publish', (done) ->
      messages = []
      Thunk = thunks()
      client1

      .on 'message', (channel, message) ->
        messages.push message
        return

      .on 'pmessage', (pattern, channel, message) ->
        messages.push message
        if message is 'end'
          should(messages).be.eql [
            'hello1'
            'hello2'
            'hello2'
            'end'
          ]
          Thunk.delay(10) done
        return

      client2.publish()(
        (error, res) ->
          should(error).be.instanceOf Error
          should(res).be.equal `undefined`
          @publish 'a', 'hello'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal 0
          client1.subscribe 'a'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal `undefined`
          @publish 'a', 'hello1'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal 1
          client1.psubscribe '*'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal `undefined`
          @publish 'a', 'hello2'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal 2
          @publish 'b', 'end'
      ) (error, res) ->
        should(error).be.equal null
        should(res).be.equal 1
        return

      return

    it 'client.pubsub', (done) ->
      Thunk = thunks()
      Thunk.call(
        client3, client1.subscribe 'a', 'b', 'ab'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal `undefined`
          @pubsub 'channels'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res.length).be.equal 3
          should(res).be.containEql 'a'
          should(res).be.containEql 'ab'
          should(res).be.containEql 'b'
          client2.subscribe 'b', 'ab', 'abc'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal `undefined`
          @pubsub 'channels', 'a*'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res.length).be.equal 3
          should(res).be.containEql 'a'
          should(res).be.containEql 'ab'
          should(res).be.containEql 'abc'
          Thunk.all (
            @pubsub 'numsub'
          ), @pubsub 'numsub', 'a', 'b', 'ab', 'd'
      )(
        (error, res) ->
          should(
            error
          ).be.equal null
          should(
            res[0]
          ).be.eql {}
          should(
            res[1]).be.eql
              a: '1'
              b: '2'
              ab: '2'
              d: '0'
          @pubsub 'numpat'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal 0
          Thunk.all (
            client1.psubscribe 'a.*', 'b.*', '123'
          ), client2.psubscribe 'a.*', 'b.*', '456'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            `undefined`
            `undefined`
          ]
          @pubsub 'numpat'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal 6
          return
      ) done
      return

    return

  return