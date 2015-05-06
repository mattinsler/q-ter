path = require 'path'
{EventEmitter} = require 'events'

loadModule = (name, lookInPath = process.cwd()) ->
  try
    require path.join(lookInPath, 'node_modules', name)
  catch err
    throw err if lookInPath is path.sep
    loadModule(name, path.join(lookInPath, '../'))

try
  q = loadModule('q')
catch err
  console.log '\nYou must npm install q in order to use q-ter\n'
  throw err

module.exports = $q = {}

$q.map = (arr, iter, slice = -1) ->
  res = Array(arr.length)
  $q.each(arr, (item, idx) ->
    q.when(iter(item, idx)).then (data) ->
      res[idx] = data
  , slice).then ->
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
    current_idx = idx++
    q.when(iter(arr[current_idx], current_idx)).then ->
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

is_dependency_method = (v) ->
  (Array.isArray(v) and typeof v[v.length - 1] is 'function')

auto_iteration = (obj, res) ->
  keys = []
  left_over_keys = []
  for k, v of obj
    if is_dependency_method(v)
      if v.slice(0, -1).every((kk) -> res.hasOwnProperty(kk))
        keys.push(k)
      else
        left_over_keys.push(k)
    else
      keys.push(k)
  
  # console.log keys, left_over_keys
  
  throw new Error('Unreachable prerequisites:' + left_over_keys.join(', ')) if keys.length is 0 and left_over_keys.length > 0
  
  q.all(
    keys.map (k) ->
      q()
      .then ->
        v = obj[k]
        if is_dependency_method(v)
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
    # console.log obj
    # console.log res
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

# want to add:
# - timeout
# - concurrency level
# - error action
# - start/stop
# $q.queue = ->
#   items = new qqueue()
#   workers = new qqueue()
# 
#   process = ->
#     $q.parallel(
#       item: items.get()
#       worker: workers.get()
#     )
#     .then (data) ->
#       q.when(data.worker(data.item))
#       .catch (err) ->
#         console.log 'CAUGHT AN ERROR. Should put an option here to stop on error if you want.'
#         # thoughts are:
#         # - re-queue the item
#         # - don't re-queue the worker
#         # - completely stop everything
#         console.log err.stack
#       .finally ->
#         workers.put(data.worker)
#     
#       process()
# 
#   process()
# 
#   {
#     push: (item) -> items.put(item)
#     poll: (fn) -> workers.put(fn)
#   }




$q.queue = ->
  # workers = new qqueue()
  
  items = []
  deferreds = []
  
  queue = new EventEmitter()
  
  check = ->
    return if items.length is 0 or deferreds.length is 0
    
    i = items.shift()
    d = deferreds.pop()
    
    if items.length is 0
      d.promise.then -> queue.emit('flush')
    
    d.resolve(i)
  
  queue.push = (item) ->
    items.push(item)
    setTimeout(check)
  
  queue.pop = ->
    d = q.defer()
    
    deferreds.push(d)
    setTimeout(check)
    
    d.promise
  
  queue.__defineGetter__ 'length', -> items.length
  
  queue
  
  
  # process = ->
  #   $q.parallel(
  #     item: items.get()
  #     worker: workers.get()
  #   )
  #   .then (data) ->
  #     q.when(data.worker(data.item))
  #     .catch (err) ->
  #       console.log 'CAUGHT AN ERROR. Should put an option here to stop on error if you want.'
  #       # thoughts are:
  #       # - re-queue the item
  #       # - don't re-queue the worker
  #       # - completely stop everything
  #       console.log err.stack
  #     .finally ->
  #       workers.put(data.worker)
  #   
  #     process()
  # 
  # process()
  # 
  # {
  #   push: (item) -> items.put(item)
  #   poll: (fn) -> workers.put(fn)
  # }
