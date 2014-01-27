path = require 'path'

try
  q = require path.join(process.cwd(), 'node_modules', 'q')
catch err
  console.log '\nYou must npm install q in order to use q-ter\n'
  throw err

module.exports = $q = {}

$q.map = (arr, iter) ->
  res = Array(arr.length)
  q.all(
    arr.map (item, idx) ->
      q.when(iter(item)).then (data) ->
        res[idx] = data
  ).then ->
    res

# $q.reduce = (arr, iter, init) ->
#   

$q.each = (arr, iter, slice = -1) ->
  d = q.defer()
  
  idx = 0
  len = arr.length
  not_done = arr.length
  running = 0
  slice = len if slice <= 0
  
  step = ->
    return if running is slice
    return d.resolve() if not_done is 0 and running is 0
    return if idx is len
        
    ++running
    q.when(iter(arr[idx++])).then ->
      --running
      --not_done
      step()
    step()
  
  step()
  
  d.promise

$q.parallel = (obj) ->
  res = {}
  q.all(
    Object.keys(obj).map (k) ->
      q()
      .then ->
        v = obj[k]
        return v() if typeof v is 'function'
        q.when(v)
      .then (v) ->
        res[k] = v
  ).then ->
    res

$q.until = (iterator, predicate) ->
  d = q.defer()
  
  step = ->
    q()
    .then ->
      return iterator() if typeof iterator is 'function'
      q.when(iterator)
    .then (res) ->
      return d.resolve() if predicate(res)
      step()
  
  step()
  .catch (err) ->
    d.reject(err)
  
  d.promise

auto_iteration = (obj, res) ->
  keys = []
  left_over_keys = []
  for k, v of obj
    if Array.isArray(v)
      if v.slice(0, -1).every((kk) -> res.hasOwnProperty(kk))
        keys.push(k)
      else
        left_over_keys.push(k)
    else
      keys.push(k)
  
  # console.log obj
  # console.log keys, left_over_keys
  
  throw new Error('Unreachable prerequisites:' + left_over_keys.join(', ')) if keys.length is 0 and left_over_keys.length > 0
  
  q.all(
    keys.map (k) ->
      q()
      .then ->
        v = obj[k]
        if Array.isArray(v)
          args = v.slice(0, -1).map((kk) -> res[kk])
          fn = v[v.length - 1]
        else
          args = []
          fn = v
        
        return fn.apply(null, args) if typeof fn is 'function'
        q.when(fn)
      .then (v) ->
        res[k] = v
  ).then ->
    delete obj[k] for k in keys
    left_over_keys

$q.auto = (obj) ->
  res = {}
  
  $q.until(
    ->
      auto_iteration(obj, res)
  ,
    (left_over_keys) ->
      left_over_keys.length is 0
  )
  .then ->
    res
