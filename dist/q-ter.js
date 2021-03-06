(function() {
  var $q, EventEmitter, auto_iteration, err, is_dependency_method, loadModule, path, q;

  path = require('path');

  EventEmitter = require('events').EventEmitter;

  loadModule = function(name, lookInPath) {
    var err;
    if (lookInPath == null) {
      lookInPath = process.cwd();
    }
    try {
      return require(path.join(lookInPath, 'node_modules', name));
    } catch (_error) {
      err = _error;
      if (lookInPath === path.sep) {
        throw err;
      }
      return loadModule(name, path.join(lookInPath, '../'));
    }
  };

  try {
    q = loadModule('q');
  } catch (_error) {
    err = _error;
    console.log('\nYou must npm install q in order to use q-ter\n');
    throw err;
  }

  module.exports = $q = {};

  $q.map = function(arr, iter, slice) {
    var res;
    if (slice == null) {
      slice = -1;
    }
    res = Array(arr.length);
    return $q.each(arr, function(item, idx) {
      return q.when(iter(item, idx)).then(function(data) {
        return res[idx] = data;
      });
    }, slice).then(function() {
      return res;
    });
  };

  $q.each = function(arr, iter, slice) {
    var d, idx, len, not_done, running, step;
    if (slice == null) {
      slice = -1;
    }
    d = q.defer();
    idx = 0;
    len = arr.length;
    not_done = arr.length;
    running = 0;
    if (slice <= 0) {
      slice = len;
    }
    step = function() {
      var current_idx;
      if (running === slice) {
        return;
      }
      if (not_done === 0 && running === 0) {
        return d.resolve();
      }
      if (idx === len) {
        return;
      }
      ++running;
      current_idx = idx++;
      q.when(iter(arr[current_idx], current_idx)).then(function() {
        --running;
        --not_done;
        return step();
      });
      return step();
    };
    step();
    return d.promise;
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

  is_dependency_method = function(v) {
    return Array.isArray(v) && typeof v[v.length - 1] === 'function';
  };

  auto_iteration = function(obj, res) {
    var k, keys, left_over_keys, v;
    keys = [];
    left_over_keys = [];
    for (k in obj) {
      v = obj[k];
      if (is_dependency_method(v)) {
        if (v.slice(0, -1).every(function(kk) {
          return res.hasOwnProperty(kk);
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
      throw new Error('Unreachable prerequisites:' + left_over_keys.join(', '));
    }
    return q.all(keys.map(function(k) {
      return q().then(function() {
        var args, fn;
        v = obj[k];
        if (is_dependency_method(v)) {
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

  $q.queue = function() {
    var check, deferreds, items, queue;
    items = [];
    deferreds = [];
    queue = new EventEmitter();
    check = function() {
      var d, i;
      if (items.length === 0 || deferreds.length === 0) {
        return;
      }
      i = items.shift();
      d = deferreds.pop();
      if (items.length === 0) {
        d.promise.then(function() {
          return queue.emit('flush');
        });
      }
      return d.resolve(i);
    };
    queue.push = function(item) {
      items.push(item);
      return setTimeout(check);
    };
    queue.pop = function() {
      var d;
      d = q.defer();
      deferreds.push(d);
      setTimeout(check);
      return d.promise;
    };
    queue.__defineGetter__('length', function() {
      return items.length;
    });
    return queue;
  };

}).call(this);
