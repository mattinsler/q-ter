path = require 'path'

try
  q = require path.join(process.cwd(), 'node_modules', 'q')
catch err
  console.log '\nYou must npm install q in order to use q-ter\n'
  throw err

exports.parallel = (obj) ->
  res = {}
  q.all(
    Object.keys(obj).map (k) ->
      q.when(obj[k]).then (v) ->
        res[k] = v
  ).then ->
    res
