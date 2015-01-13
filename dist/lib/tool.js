exports.setPrivate = function(ctx, key, value) {
  Object.defineProperty(ctx, key, {
    enumerable: false,
    configurable: false,
    writable: false,
    value: value
  });
};

exports.slice = function(args, start) {
  var len, ret;
  start = start || 0;
  if (start >= args.length) {
    return [];
  }
  len = args.length;
  ret = Array(len - start);
  while (len-- > start) {
    ret[len - start] = args[len];
  }
  return ret;
};

exports.log = function() {
  console.log.apply(console, arguments);
};

exports.each = function(obj, iterator, context, arrayLike) {
  var index, key, _obj_;
  if (!obj) {
    return;
  }
  if (arrayLike == null) {
    arrayLike = Array.isArray(obj);
  }
  if (arrayLike) {
    for (index in obj) {
      _obj_ = obj[index];
      iterator.call(context, _obj_, index, obj);
    }
  } else {
    for (key in obj) {
      if (obj.hasOwnProperty(key)) {
        iterator.call(context, obj[key], key, obj);
      }
    }
  }
};
