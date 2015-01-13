#global
redis = require '../index'

client =
  redis.createClient
    database: 1

client.on 'connect', ->
  console.log 'redis connected!'

client.info(
  'server'
)(
  (error, res) ->
    console.log 'redis server info: '
    , JSON.stringify res, null, 2
    console.log 'redis client status: '
    , JSON.stringify @clientState(), null, 2
    @dbsize()
)(
  (error, res) ->
    console.log 'surrent database size: ', res
    @select 0
) (error, res) ->
    console.log 'select database 0: ', res
    console.log 'redis client status: '
    , JSON.stringify @clientState(), null, 2
    @clientEnd()
