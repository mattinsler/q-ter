q = require 'q'
$q = require '../lib/q-ter'

x = 1

$q.until ->
  q.delay(1000)
  .then ->
    x += 1
, (res) ->
  console.log res
  res is 10
.then ->
  console.log 'DONE'
.catch(console.log)
