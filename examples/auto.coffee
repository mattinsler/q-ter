q = require 'q'
$q = require '../lib/q-ter'

$q.auto(
  foo: ['bar', (bar) ->
    'Yo ' + bar
  ]
  bar: ->
    q.delay(2000)
    .then ->
      'hello'
)
.then(console.log)
.catch(console.log)
