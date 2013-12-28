q = require 'q'
$q = require '../lib/q-ter'

$q.parallel(
  foo: ->
    q.delay(2000)
    .then ->
      'bar'
).then ->
  console.log arguments
.catch(console.log)
