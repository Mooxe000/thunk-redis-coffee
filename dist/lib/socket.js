var Command, Thunk, execQueue, flushAll, flushForMonitor, flushPending, initResp, initSocket, isMessageReply, isSubReply, isUnSubReply, messageTypes, net, noop, resp, sendCommand, subReplyTypes, tool, unSubReplyTypes, util;

net = require('net');

util = require('util');

Thunk = require('thunks')();

resp = require('respjs');

tool = require('./tool');

initSocket = function(redis, options, socketState) {
  var checkReady, socket, waitForAuth, waitForSelect;
  waitForAuth = false;
  waitForSelect = false;
  socket = redis._socket = net.createConnection(options);
  socket.setNoDelay(redis._options.noDelay);
  socket.setKeepAlive(redis._options.keepAlive);
  socket.setTimeout(redis._options.timeout);
  socket.pendingWatcher = null;
  socket.redisConnected = false;
  socket.commandsHighWater = redis._options.commandsHighWater;
  socket.returnBuffers = redis._options.returnBuffers;
  socket.debugMode = redis._options.debugMode;
  tool.setPrivate(socket, 'commandQueue', socketState.commandQueue);
  tool.setPrivate(socket, 'frequency', socketState.frequency);
  checkReady = function() {
    if (waitForAuth || waitForSelect) {
      return execQueue(redis, true);
    }
    redis._redisState.connected = socket.redisConnected = true;
    redis.emit('connect');
    execQueue(redis);
  };
  if (redis._options.authPass) {
    waitForAuth = true;
    redis.auth(redis._options.authPass)(function(error) {
      if (error) {
        return socket.emit('error', error);
      }
      waitForAuth = false;
      checkReady();
    });
  }
  if (redis._options.database) {
    waitForSelect = true;
    redis.select(redis._options.database)(function(error) {
      if (error) {
        return socket.emit('error', error);
      }
      waitForSelect = false;
      checkReady();
    });
  }
  socket.on('connect', checkReady).on('data', function(chunk) {
    var reply;
    reply = socket.pendingWatcher;
    if (socket.debugMode) {
      tool.log({
        socketChunk: chunk
      });
    }
    if (!reply) {
      return redis.emit('error', new Error('Unexpected reply: ' + chunk));
    }
    if (!reply.resp) {
      reply.resp = initResp(redis, reply);
    }
    reply.resp.feed(chunk);
  }).on('error', function(error) {
    flushAll(socket, error);
    redis.emit('error', error);
  }).on('close', function(hadError) {
    flushAll(socket, new Error('The redis connection was closed'));
    redis.emit('close', hadError);
  }).on('timeout', function() {
    var error;
    error = new Error('The redis connection was timeout');
    redis.emit('timeout');
    if (socketState.attempts <= redis._options.maxAttempts) {
      flushPending(socket, error);
      socket.removeAllListeners();
      socket.destroy();
      redis.emit('reconnecting', {
        delay: redis._options.retryDelay,
        attempts: ++socketState.attempts
      });
      setTimeout(function() {
        initSocket(redis, options, {
          attempts: socketState.attempts,
          commandQueue: socket.commandQueue,
          frequency: socket.frequency
        });
      }, redis._options.retryDelay);
    } else {
      flushAll(socket, error);
      redis.end();
    }
  }).on('end', function() {
    flushAll(socket, new Error('The redis connection was ended'));
    redis.end();
  }).on('queueDrain', function() {
    redis.emit('drain');
  });
};

initResp = function(redis, reply) {
  var redisState, socket;
  socket = redis._socket;
  redisState = redis._redisState;
  return new resp.Resp({
    expectResCount: reply.commands.length,
    returnBuffers: socket.returnBuffers
  }).on('error', function(error) {
    if (socket.debugMode) {
      tool.log({
        respError: error
      });
    }
    flushPending(socket, error);
    redis.emit('error', error);
  }).on('data', function(data) {
    var command;
    if (socket.debugMode) {
      tool.log({
        respData: data
      });
    }
    command = reply.commands[0];
    if (redisState.monitorMode && (!command || command.name !== 'quit')) {
      return redis.emit('monitor', data);
    }
    if (isMessageReply(data)) {
      return redis.emit.apply(redis, data);
    }
    if (isUnSubReply(data)) {
      if (redisState.pubSubMode && !data[2]) {
        redisState.pubSubMode = false;
        if (command) {
          this.autoEnd(reply.commands.length);
        }
      }
      if (!command) {
        this.end();
      } else if (data[0] === command.name) {
        reply.commands.shift();
        command.callback();
      }
      return redis.emit.apply(redis, data);
    }
    reply.commands.shift();
    if (!command) {
      return redis.emit('error', new Error('Unexpected reply: ' + data));
    }
    if (util.isError(data)) {
      return command.callback(data);
    }
    if (command.name === 'monitor') {
      redisState.monitorMode = true;
      this.autoEnd();
      return command.callback(null, data);
    }
    if (isSubReply(data)) {
      if (!redisState.pubSubMode) {
        redisState.pubSubMode = true;
        this.autoEnd();
      }
      command.callback();
      return redis.emit.apply(redis, data);
    }
    return command.callback(null, data);
  }).on('end', function() {
    socket.pendingWatcher = null;
    execQueue(redis);
  });
};

sendCommand = function(redis, command, args, additionalCallbacks) {
  return Thunk.call(redis, function(callback) {
    var buffer, error;
    buffer = void 0;
    if (redis._redisState.ended) {
      return callback(new Error('The redis connection was ended'));
    }
    if (!Array.isArray(args)) {
      args = [];
    }
    args.unshift(command);
    try {
      buffer = resp.bufferify(args);
    } catch (_error) {
      error = _error;
      return callback(error);
    }
    this._socket.commandQueue.push(new Command(command, buffer, callback, additionalCallbacks));
    execQueue(this);
  });
};

Command = function(command, data, callback, additionalCallbacks) {
  this.name = command;
  this.data = data;
  this.callback = callback;
  this.additionalCallbacks = additionalCallbacks || 0;
};

noop = function() {};

execQueue = function(redis, init) {
  var command, count, pendingCommands, pendingWatcher, socket;
  socket = redis._socket;
  if (!init && !socket.redisConnected) {
    return;
  }
  if (!socket.commandQueue.length) {
    return socket.emit('queueDrain');
  }
  if (redis._redisState.pubSubMode || redis._redisState.monitorMode) {
    if (redis._redisState.monitorMode) {
      flushForMonitor(socket);
    }
  } else if (socket.pendingWatcher) {
    return;
  } else {
    socket.pendingWatcher = {
      commands: []
    };
  }
  pendingCommands = 0;
  count = socket.commandsHighWater;
  pendingWatcher = socket.pendingWatcher;
  while (socket.commandQueue.length && count--) {
    command = socket.commandQueue.shift();
    if (socket.debugMode) {
      tool.log({
        socketWrite: command.data.toString()
      });
    }
    pendingWatcher.commands.push({
      name: command.name,
      callback: command.callback
    });
    while (command.additionalCallbacks--) {
      pendingWatcher.commands.push({
        name: command.name,
        callback: noop
      });
    }
    pendingCommands++;
    if (command.name === 'monitor') {
      flushForMonitor(socket);
    }
    if (!socket.write(command.data)) {
      break;
    }
  }
  socket.frequency[pendingCommands] = 1 + (socket.frequency[pendingCommands] || 0);
};

flushForMonitor = function(socket) {
  var error, queue;
  error = new Error('Only QUIT allowed in this monitor.');
  queue = socket.commandQueue;
  while (queue.length && queue[0].name !== 'quit') {
    queue.shift().callback(error);
  }
};

flushPending = function(socket, error) {
  if (!socket.pendingWatcher) {
    return;
  }
  tool.each(socket.pendingWatcher.commands, function(command) {
    command.callback(error);
  }, null, true);
  socket.pendingWatcher = null;
};

flushAll = function(socket, error) {
  var queue;
  flushPending(socket, error);
  queue = socket.commandQueue;
  while (queue.length) {
    queue.shift().callback(error);
  }
};

messageTypes = {
  message: true,
  pmessage: true
};

isMessageReply = function(reply) {
  return reply && messageTypes.hasOwnProperty(reply[0]);
};

subReplyTypes = {
  subscribe: true,
  psubscribe: true
};

isSubReply = function(reply) {
  return reply && subReplyTypes.hasOwnProperty(reply[0]);
};

unSubReplyTypes = {
  unsubscribe: true,
  punsubscribe: true
};

isUnSubReply = function(reply) {
  return reply && unSubReplyTypes.hasOwnProperty(reply[0]);
};

exports.initSocket = initSocket;

exports.sendCommand = sendCommand;
