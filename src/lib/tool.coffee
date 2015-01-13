
exports.setPrivate = (ctx, key, value) ->
  Object.defineProperty ctx, key,
    enumerable: false
    configurable: false
    writable: false
    value: value
  return

exports.slice = (args, start) ->
  start = start or 0
  return []  if start >= args.length
  len = args.length
  ret = Array len - start
  ret[len - start] = args[len]  while len-- > start
  ret

exports.log = ->
  console.log.apply console, arguments
  return

exports.each = (obj, iterator, context, arrayLike) ->
  return  unless obj
  arrayLike = Array.isArray obj  unless arrayLike?
  if arrayLike
    for index, _obj_ of obj
      iterator.call context, _obj_, index, obj
  else
    for key of obj
      iterator.call context, obj[key], key, obj  if obj.hasOwnProperty key
  return