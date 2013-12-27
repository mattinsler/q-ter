q = require 'q'
$q = require '../lib/q-ter'

# $q.parallel(
#   foo: ->
#     q.delay(2000)
#     .then ->
#       'bar'
# ).then ->
#   console.log arguments

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

# x = 1
# 
# $q.until ->
#   q.delay(1000)
#   .then ->
#     x += 1
# , (res) ->
#   console.log res
#   res is 10
# .then ->
#   console.log 'DONE'
