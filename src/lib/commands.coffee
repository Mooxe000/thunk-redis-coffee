Thunk = do require 'thunks'
tool = require './tool'
{sendCommand} = require './socket'

# (Redis 2.8.17) http://redis.io/commands
commands = [
  # Keys
  'del', 'dump', 'exists', 'expire', 'expireat', 'keys', 'migrate', 'move'
  'object', 'persist', 'pexpire', 'pexpireat', 'pttl', 'randomkey', 'rename'
  'renamenx', 'restore', 'sort', 'ttl', 'type', 'scan'
  # Strings
  'append', 'bitcount', 'bitop', 'bitpos', 'decr', 'decrby', 'get', 'getbit', 'getrange'
  'getset', 'incr', 'incrby', 'incrbyfloat', 'mget', 'mset', 'msetnx', 'psetex'
  'set', 'setbit', 'setex', 'setnx', 'setrange', 'strlen'
  # Hashes
  'hdel', 'hexists', 'hget', 'hgetall', 'hincrby', 'hincrbyfloat', 'hkeys', 'hlen'
  'hmget', 'hmset', 'hset', 'hsetnx', 'hvals', 'hscan'
  # Lists
  'blpop', 'brpop', 'brpoplpush', 'lindex', 'linsert', 'llen', 'lpop', 'lpush'
  'lpushx', 'lrange', 'lrem', 'lset', 'ltrim', 'rpop', 'rpoplpush', 'rpush', 'rpushx'
  # Sets
  'sadd', 'scard', 'sdiff', 'sdiffstore', 'sinter', 'sinterstore', 'sismember'
  'smembers', 'smove', 'spop', 'srandmember', 'srem', 'sunion', 'sunionstore', 'sscan'
  # Sorted Sets
  'zadd', 'zcard', 'zcount', 'zincrby', 'zinterstore', 'zlexcount', 'zrange', 'zrangebylex'
  'zrevrangebylex', 'zrangebyscore', 'zrank', 'zrem', 'zremrangebylex', 'zremrangebyrank'
  'zremrangebyscore', 'zrevrange', 'zrevrangebyscore', 'zrevrank', 'zscore', 'zunionstore', 'zsan'
  # HyperLog
  'pfadd', 'pfcount', 'pfmerge'
  # Pub/Sub
  'psubscribe', 'publish', 'pubsub', 'punsubscribe', 'subscribe', 'unsubscribe'
  # Transaction
  'discard', 'exec', 'multi', 'unwatch', 'watch'
  # Scripting
  'eval', 'evalsha', 'script'
  # Connection
  'auth', 'echo', 'ping', 'quit', 'select'
  # Server
  'bgrewriteaof', 'bgsave', 'client', 'cluster', 'command', 'config', 'dbsize', 'debug', 'flushall'
  'flushdb', 'info', 'lastsave', 'monitor', 'role', 'save', 'shutdown', 'slaveof'
  'slowlog', 'sync', 'time'
]

exports.initCommands = (proto) ->

  proto.clientCommands = commands

  tool.each commands, (command) ->
    proto[command] = ->
      sendCommand this, command, tool.slice(arguments)
    return
  , null, true

  # overrides

  # Parse the reply from INFO into a hash.
  proto.info = (section) ->
    sendCommand(this, 'info', tool.slice(arguments)) formatInfo

  # Set the client's password property to the given value on AUTH.
  proto.auth = (password) ->
    sendCommand(this, 'auth', [password]) (error, reply) ->
      error = error or new Error('Auth failed: ' + reply)  if reply isnt 'OK'
      throw error  if error
      reply

  # Set the client's database property to the database number on SELECT.
  proto.select = (database) ->
    sendCommand(this, 'select', [database]) (error, reply) ->
      error = error or new Error('Select ' + database + ' failed: ' + reply)  if reply isnt 'OK'
      throw error  if error
      @_redisState.database = database
      reply

  # Optionally accept a hash as the only argument to MSET.
  proto.mset = (hash) ->
    args = (if (typeof hash is 'object') then toArray(hash, []) else tool.slice(arguments))
    sendCommand this, 'mset', args

  # Optionally accept a hash as the only argument to MSETNX.
  proto.msetnx = (hash) ->
    args = (if (typeof hash is 'object') then toArray(hash, []) else tool.slice(arguments))
    sendCommand this, 'msetnx', args

  # Optionally accept a hash as the first argument to HMSET after the key.
  proto.hmset = (key, hash) ->
    args = (if (typeof hash is 'object') then toArray(hash, [key]) else tool.slice(arguments))
    sendCommand this, 'hmset', args

  # Make a hash from the result of HGETALL.
  proto.hgetall = ->
    sendCommand(this, 'hgetall', tool.slice(arguments)) toHash

  proto.hscan = ->
    sendCommand(this, 'hscan', tool.slice(arguments)) (error, res) ->
      throw error  if error
      res[1] = toHash(null, res[1])
      res

  proto.pubsub = ->
    args = tool.slice(arguments)
    sendCommand(this, 'pubsub', tool.slice(arguments)) (error, res) ->
      throw error  if error
      res = toHash(null, res)  if args[0].toLowerCase() is 'numsub'
      res

  proto.quit = ->
    sendCommand(this, 'quit') (error, res) ->
      throw error  if error
      @clientEnd()
      res

  tool.each [
    'psubscribe'
    'punsubscribe'
    'subscribe'
    'unsubscribe'
  ], (command) ->
    proto[command] = ->
      args = tool.slice(arguments)
      sendCommand this, command, args, (if args.length then (args.length - 1) else 0)
    return
  , null, true

  tool.each commands, (command) ->
    proto[command.toUpperCase()] = proto[command]
    return
  , null, true

  return

# ------
# HELPER
# ------
toArray = (hash, array) ->
  tool.each hash, ((value, key) ->
    array.push key, value
    return
  ), null
  array

formatInfo = (error, info) ->
  throw error  if error
  hash = {}
  tool.each info.split('\r\n'), ((line) ->
    index = line.indexOf(':')
    return  if index is -1
    name = line.slice(0, index)
    hash[name] = line.slice(index + 1)
    return
  ), null, true
  hash

toHash = (error, array) ->
  throw error  if error
  hash = {}
  i = 0
  len = array.length

  while i < len
    hash[array[i]] = array[i + 1]
    i += 2
  hash
