(function() {
  var err, path, q;

  path = require('path');

  try {
    q = require(path.join(process.cwd(), 'node_modules', 'q'));
  } catch (_error) {
    err = _error;
    console.log('\nYou must npm install q in order to use q-ter\n');
    throw err;
  }

  exports.parallel = function(obj) {
    var res;
    res = {};
    return q.all(Object.keys(obj).map(function(k) {
      return q.when(obj[k]).then(function(v) {
        return res[k] = v;
      });
    })).then(function() {
      return res;
    });
  };

}).call(this);
