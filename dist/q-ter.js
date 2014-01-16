(function() {
  var $q, auto_iteration, err, path, q;

  path = require('path');

  try {
    q = require(path.join(process.cwd(), 'node_modules', 'q'));
  } catch (_error) {
    err = _error;
    console.log('\nYou must npm install q in order to use q-ter\n');
    throw err;
  }

  module.exports = $q = {};

  $q.map = function(arr, iter) {
    var res;
    res = Array(arr.length);
    return q.all(arr.map(function(item, idx) {
      return q.when(iter(item)).then(function(data) {
        return res[idx] = data;
      });
    })).then(function() {
      return res;
    });
  };

  $q.parallel = function(obj) {
    var res;
    res = {};
    return q.all(Object.keys(obj).map(function(k) {
      return q().then(function() {
        var v;
        v = obj[k];
        if (typeof v === 'function') {
          return v();
        }
        return q.when(v);
      }).then(function(v) {
        return res[k] = v;
      });
    })).then(function() {
      return res;
    });
  };

  $q.until = function(iterator, predicate) {
    var d, step;
    d = q.defer();
    step = function() {
      return q().then(function() {
        if (typeof iterator === 'function') {
          return iterator();
        }
        return q.when(iterator);
      }).then(function(res) {
        if (predicate(res)) {
          return d.resolve();
        }
        return step();
      });
    };
    step()["catch"](function(err) {
      return d.reject(err);
    });
    return d.promise;
  };

  auto_iteration = function(obj, res) {
    var k, keys, left_over_keys, v;
    keys = [];
    left_over_keys = [];
    for (k in obj) {
      v = obj[k];
      if (Array.isArray(v)) {
        if (v.slice(0, -1).every(function(kk) {
          return res[kk] != null;
        })) {
          keys.push(k);
        } else {
          left_over_keys.push(k);
        }
      } else {
        keys.push(k);
      }
    }
    if (keys.length === 0 && left_over_keys.length > 0) {
      throw new Error('Unreachable prerequisites');
    }
    return q.all(keys.map(function(k) {
      return q().then(function() {
        var args, fn;
        v = obj[k];
        if (Array.isArray(v)) {
          args = v.slice(0, -1).map(function(kk) {
            return res[kk];
          });
          fn = v[v.length - 1];
        } else {
          args = [];
          fn = v;
        }
        if (typeof fn === 'function') {
          return fn.apply(null, args);
        }
        return q.when(fn);
      }).then(function(v) {
        return res[k] = v;
      });
    })).then(function() {
      var _i, _len;
      for (_i = 0, _len = keys.length; _i < _len; _i++) {
        k = keys[_i];
        delete obj[k];
      }
      return left_over_keys;
    });
  };

  $q.auto = function(obj) {
    var res;
    res = {};
    return $q.until(function() {
      return auto_iteration(obj, res);
    }, function(left_over_keys) {
      return left_over_keys.length === 0;
    }).then(function() {
      return res;
    });
  };

}).call(this);
