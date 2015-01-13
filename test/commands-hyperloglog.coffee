#global describe, it, before, after, beforeEach, afterEach
should = require 'should'
Thunk = do require 'thunks'
redis = require '../index'

module.exports = ->

  describe 'commands:HyperLogLog', ->

    client = undefined

    before ->
      client = redis.createClient(database: 0)
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

    it 'client.pfadd, client.pfcount, client.pfmerge', (done) ->
      client.pfadd(
        'db', 'Redis', 'MongoDB', 'MySQL'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal 1
          Thunk.all (
            @pfcount 'db'
          ), (
            @pfadd 'db'
          ), 'Redis'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            3
            0
          ]
          Thunk.all (
            @pfadd 'db', 'PostgreSQL'
          ), @pfcount 'db'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            1
            4
          ]
          @pfadd 'alphabet', 'a', 'b', 'c'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.equal 1
          Thunk.all (
            @pfcount 'alphabet'
          ), @pfcount 'alphabet', 'db'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            3
            7
          ]
          Thunk.all (
            @pfmerge 'x', 'alphabet', 'db'
          ), @pfcount 'x'
      )(
        (error, res) ->
          should(error).be.equal null
          should(res).be.eql [
            'OK'
            7
          ]
          return
      ) done
      return

    return

  return