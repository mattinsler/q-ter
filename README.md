# q-ter

Q Stuff

## Installation

```bash
$ npm install --save q-ter
```

## Usage

```javascript
var $q = require('q-ter');

$q.parallel({
  foo: function() {
    return 'foo';
  },
  bar: function() {
    var fs = require('fs');
    return q.nfcall(fs.readFile('/foo/bar/baz'));
  }
}).then(function(data) {
  console.log(data.foo, data.bar);
});

$q.auto({
  foo: ['bar', function(bar) {
    var q = require('q');
    return q.delay(2000).then(function() {
      return 'foo ' + bar;
    });
  }],
  bar: function() {
    return 'I like bars!';
  }
}).then(function(data) {
  console.log(data.foo, data.bar);
});

var x = 0;
$q.until(function() {
  var q = require('q');
  return q.delay(1000).then(function() {
    x += 1;
  });
}, function() {
  return x === 10;
}).then(function() {
  console.log(x);
});
```

## Methods

### $q.until(iterator, predicate)

Runs `iterator` until `predicate` returns true.

### $q.parallel(config)

Runs all methods in parallel.

### $q.auto(config)
