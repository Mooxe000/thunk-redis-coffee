#global describe, it, before, after, beforeEach, afterEach
should = require 'should'
thunks = require 'thunks'
redis = require '../index'

module.exports = ->

  describe 'commands:Transaction', ->
    client1 = client2 = undefined

    beforeEach (done) ->

      client1 = redis.createClient debugMode: false
      client1.on 'error', (error) ->
        console.error 'redis client:', error
        return

      client2 = redis.createClient debugMode: false
      client2.on 'error', (error) ->
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
      return

    it 'client.multi, client.discard, client.exec', (done) ->
      Thunk = thunks()
      client1.multi()(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal 'OK'
          Thunk.all (
            @incr 'users'
          ), (
            @incr 'users'
          ), @incr 'users'
      )(
        (error, res) ->
          should(res).be.eql [
            'QUEUED'
            'QUEUED'
            'QUEUED'
          ]
          @exec()
      )(
        (error, res) ->
          should(res).be.eql [
            '1'
            '2'
            '3'
          ]
          @discard()
      )(
        (error, res) ->
          should(error).be.instanceOf Error
          Thunk.all @multi(), @ping(), @ping(), @discard()
      )(
        (error, res) ->
          should(res).be.eql [
            'OK'
            'QUEUED'
            'QUEUED'
            'OK'
          ]
          @exec()
      )(
        (error, res) ->
          should(error).be.instanceOf Error
          return
      ) done
      return

    it 'client.watch, client.unwatch', (done) ->
      Thunk = thunks()
      client1.watch(
        'users'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal 'OK'
          Thunk.all @multi(), (
            @incr 'users'
          ), @incr 'users'
      )(
        (error, res) ->
          should(res).be.eql [
            'OK'
            'QUEUED'
            'QUEUED'
          ]
          client2.incr 'users'
      )(
        (error, res) ->
          should(res).be.equal 1
          @exec()
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal null
          Thunk.all (
            @watch 'i'
          ), @unwatch()
          , @multi()
          , (
            @incr 'i'
          ), @incr 'i'
      )(
        (error, res) ->
          should(res).be.eql [
            'OK'
            'OK'
            'OK'
            'QUEUED'
            'QUEUED'
          ]
          client2.incr 'i'
      )(
        (error, res) ->
          should(res).be.equal 1
          @exec()
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            2
            3
          ]
          return
      ) done
      return

    return

  return