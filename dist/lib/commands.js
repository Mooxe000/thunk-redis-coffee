var Thunk, commands, formatInfo, sendCommand, toArray, toHash, tool;

Thunk = require('thunks')();

tool = require('./tool');

sendCommand = require('./socket').sendCommand;

commands = ['del', 'dump', 'exists', 'expire', 'expireat', 'keys', 'migrate', 'move', 'object', 'persist', 'pexpire', 'pexpireat', 'pttl', 'randomkey', 'rename', 'renamenx', 'restore', 'sort', 'ttl', 'type', 'scan', 'append', 'bitcount', 'bitop', 'bitpos', 'decr', 'decrby', 'get', 'getbit', 'getrange', 'getset', 'incr', 'incrby', 'incrbyfloat', 'mget', 'mset', 'msetnx', 'psetex', 'set', 'setbit', 'setex', 'setnx', 'setrange', 'strlen', 'hdel', 'hexists', 'hget', 'hgetall', 'hincrby', 'hincrbyfloat', 'hkeys', 'hlen', 'hmget', 'hmset', 'hset', 'hsetnx', 'hvals', 'hscan', 'blpop', 'brpop', 'brpoplpush', 'lindex', 'linsert', 'llen', 'lpop', 'lpush', 'lpushx', 'lrange', 'lrem', 'lset', 'ltrim', 'rpop', 'rpoplpush', 'rpush', 'rpushx', 'sadd', 'scard', 'sdiff', 'sdiffstore', 'sinter', 'sinterstore', 'sismember', 'smembers', 'smove', 'spop', 'srandmember', 'srem', 'sunion', 'sunionstore', 'sscan', 'zadd', 'zcard', 'zcount', 'zincrby', 'zinterstore', 'zlexcount', 'zrange', 'zrangebylex', 'zrevrangebylex', 'zrangebyscore', 'zrank', 'zrem', 'zremrangebylex', 'zremrangebyrank', 'zremrangebyscore', 'zrevrange', 'zrevrangebyscore', 'zrevrank', 'zscore', 'zunionstore', 'zsan', 'pfadd', 'pfcount', 'pfmerge', 'psubscribe', 'publish', 'pubsub', 'punsubscribe', 'subscribe', 'unsubscribe', 'discard', 'exec', 'multi', 'unwatch', 'watch', 'eval', 'evalsha', 'script', 'auth', 'echo', 'ping', 'quit', 'select', 'bgrewriteaof', 'bgsave', 'client', 'cluster', 'command', 'config', 'dbsize', 'debug', 'flushall', 'flushdb', 'info', 'lastsave', 'monitor', 'role', 'save', 'shutdown', 'slaveof', 'slowlog', 'sync', 'time'];

exports.initCommands = function(proto) {
  proto.clientCommands = commands;
  tool.each(commands, function(command) {
    proto[command] = function() {
      return sendCommand(this, command, tool.slice(arguments));
    };
  }, null, true);
  proto.info = function(section) {
    return sendCommand(this, 'info', tool.slice(arguments))(formatInfo);
  };
  proto.auth = function(password) {
    return sendCommand(this, 'auth', [password])(function(error, reply) {
      if (reply !== 'OK') {
        error = error || new Error('Auth failed: ' + reply);
      }
      if (error) {
        throw error;
      }
      return reply;
    });
  };
  proto.select = function(database) {
    return sendCommand(this, 'select', [database])(function(error, reply) {
      if (reply !== 'OK') {
        error = error || new Error('Select ' + database + ' failed: ' + reply);
      }
      if (error) {
        throw error;
      }
      this._redisState.database = database;
      return reply;
    });
  };
  proto.mset = function(hash) {
    var args;
    args = (typeof hash === 'object' ? toArray(hash, []) : tool.slice(arguments));
    return sendCommand(this, 'mset', args);
  };
  proto.msetnx = function(hash) {
    var args;
    args = (typeof hash === 'object' ? toArray(hash, []) : tool.slice(arguments));
    return sendCommand(this, 'msetnx', args);
  };
  proto.hmset = function(key, hash) {
    var args;
    args = (typeof hash === 'object' ? toArray(hash, [key]) : tool.slice(arguments));
    return sendCommand(this, 'hmset', args);
  };
  proto.hgetall = function() {
    return sendCommand(this, 'hgetall', tool.slice(arguments))(toHash);
  };
  proto.hscan = function() {
    return sendCommand(this, 'hscan', tool.slice(arguments))(function(error, res) {
      if (error) {
        throw error;
      }
      res[1] = toHash(null, res[1]);
      return res;
    });
  };
  proto.pubsub = function() {
    var args;
    args = tool.slice(arguments);
    return sendCommand(this, 'pubsub', tool.slice(arguments))(function(error, res) {
      if (error) {
        throw error;
      }
      if (args[0].toLowerCase() === 'numsub') {
        res = toHash(null, res);
      }
      return res;
    });
  };
  proto.quit = function() {
    return sendCommand(this, 'quit')(function(error, res) {
      if (error) {
        throw error;
      }
      this.clientEnd();
      return res;
    });
  };
  tool.each(['psubscribe', 'punsubscribe', 'subscribe', 'unsubscribe'], function(command) {
    proto[command] = function() {
      var args;
      args = tool.slice(arguments);
      return sendCommand(this, command, args, (args.length ? args.length - 1 : 0));
    };
  }, null, true);
  tool.each(commands, function(command) {
    proto[command.toUpperCase()] = proto[command];
  }, null, true);
};

toArray = function(hash, array) {
  tool.each(hash, (function(value, key) {
    array.push(key, value);
  }), null);
  return array;
};

formatInfo = function(error, info) {
  var hash;
  if (error) {
    throw error;
  }
  hash = {};
  tool.each(info.split('\r\n'), (function(line) {
    var index, name;
    index = line.indexOf(':');
    if (index === -1) {
      return;
    }
    name = line.slice(0, index);
    hash[name] = line.slice(index + 1);
  }), null, true);
  return hash;
};

toHash = function(error, array) {
  var hash, i, len;
  if (error) {
    throw error;
  }
  hash = {};
  i = 0;
  len = array.length;
  while (i < len) {
    hash[array[i]] = array[i + 1];
    i += 2;
  }
  return hash;
};
