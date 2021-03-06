// Generated by CoffeeScript 1.12.1
(function() {
  var $, $as_line, $async, $show, $split, CND, D, FS, O, OS, PATH, PS, V8PROFILER, badge, debug, echo, error, flamegraph, flamegraph_from_stream, format_float, format_integer, get_fingerprint, help, info, mkdirp, new_numeral, new_settings, new_spin, report, rpr, running_in_devtools, start_profile, step, stop_profile, through2, warn, whisper, write_flamegraph;

  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'BASIC-STREAM-BENCHMARKS';

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  info = CND.get_logger('info', badge);

  help = CND.get_logger('help', badge);

  whisper = CND.get_logger('whisper', badge);

  echo = CND.echo.bind(CND);

  PATH = require('path');

  FS = require('fs');

  OS = require('os');

  through2 = require('through2');

  $split = require('binary-split');

  new_numeral = require('numeral');

  format_float = function(x) {
    return (new_numeral(x)).format('0,0.000');
  };

  format_integer = function(x) {
    return (new_numeral(x)).format('0,0');
  };

  step = require('coffeenode-suspend').step;

  O = {};

  O.inputs = {};

  O.inputs['long'] = PATH.resolve(__dirname, '../test-data/Unicode-NamesList.txt');

  O.inputs['short'] = PATH.resolve(__dirname, '../test-data/Unicode-NamesList-short.txt');

  O.inputs['tiny'] = PATH.resolve(__dirname, '../test-data/Unicode-NamesList-tiny.txt');

  D = require('pipedreams');

  $ = D.$, $async = D.$async;


  /* TAINT use installed version of PipeStreams */

  PS = require('../../pipestreams');


  /* Avoid to try to require `v8-profiler` when running this module with `devtool`: */

  running_in_devtools = console.profile != null;

  V8PROFILER = null;

  if (!running_in_devtools) {
    try {
      V8PROFILER = require('v8-profiler');
    } catch (error1) {
      error = error1;
      if (error['code'] !== 'MODULE_NOT_FOUND') {
        throw error;
      }
      warn("unable to `require v8-profiler`");
    }
  }

  flamegraph = require('flamegraph');

  flamegraph_from_stream = require('flamegraph/from-stream');

  mkdirp = require('mkdirp');

  $show = function() {
    return through2(function(data, encoding, callback) {
      this.push(data);
      return callback();
    });
  };

  $as_line = function() {
    return through2(function(data, encoding, callback) {
      this.push(data + '\n');
      return callback();
    });
  };

  get_fingerprint = function() {
    var R, cpu_nfo;
    cpu_nfo = OS.cpus()[0];
    R = cpu_nfo['model'];
    R = R.toLowerCase();
    R = R.replace(/[^-a-z0-9]/g, '-');
    R = R.replace(/-+/g, '-');
    R = R.replace(/^-/, '');
    R = R.replace(/-$/, '');
    return R;
  };

  new_settings = function(settings) {
    var R;
    R = Object.assign({}, settings);
    R.byte_count = 0;
    R.item_count = 0;
    R.t0 = null;
    R.t1 = null;
    R.fingerprint = get_fingerprint();
    R.job_name = R.fingerprint + "," + R.flavor + "," + R.n + "," + R.mode;
    return R;
  };

  report = function(S) {
    var bps, bps_txt, byte_count_txt, dts, dts_txt, ips, ips_txt, item_count_txt, line;
    format_integer = function(x) {
      return "" + x;
    };
    format_float = function(x) {
      return x.toFixed(3);
    };
    dts = (S.t1 - S.t0) / 1000;
    bps = S.byte_count / dts;
    ips = S.item_count / dts;
    byte_count_txt = format_integer(S.byte_count);
    item_count_txt = format_integer(S.item_count);
    dts_txt = format_float(dts);
    bps_txt = format_float(bps);
    ips_txt = format_float(ips);
    line = [];
    if (report.is_first) {
      report.is_first = false;
      echo(CND.lime(['job', 'n', 'mode', 'dt', 'bytes', 'items', 'bps', 'ips'].join('\t')));
    }
    line.push(S.job_name);
    line.push(S.n);
    line.push(S.mode);
    line.push(dts_txt);
    line.push(byte_count_txt);
    line.push(item_count_txt);
    line.push(bps_txt);
    line.push(ips_txt);
    echo(CND.steel(line.join('\t')));
    return null;
  };

  report.is_first = true;

  start_profile = function(S) {
    S.t0 = Date.now();
    if (running_in_devtools) {
      return console.profile(S.job_name);
    } else if (V8PROFILER != null) {
      return V8PROFILER.startProfiling(S.job_name);
    }
  };

  stop_profile = function(S, handler) {
    if (running_in_devtools) {
      return console.profileEnd(S.job_name);
    } else if (V8PROFILER != null) {
      return step(function*(resume) {
        var profile, profile_data;
        profile = V8PROFILER.stopProfiling(S.job_name);
        profile_data = (yield profile["export"](resume));
        S.profile_name = "profile-" + S.job_name + ".json";
        S.profile_home = PATH.resolve(__dirname, '../results', S.fingerprint, 'profiles');
        mkdirp.sync(S.profile_home);
        S.profile_path = PATH.resolve(S.profile_home, S.profile_name);
        FS.writeFileSync(S.profile_path, profile_data);
        return handler();
      });
    }
  };

  write_flamegraph = function(S, handler) {
    var source;
    if (running_in_devtools) {
      return;
    }
    S.flamegraph_name = "flamegraph-" + S.job_name + ".svg";
    S.flamegraph_home = PATH.resolve(__dirname, '../results', S.fingerprint, 'flamegraphs');
    mkdirp.sync(S.flamegraph_home);
    S.flamegraph_path = PATH.resolve(S.flamegraph_home, S.flamegraph_name);
    source = D.new_stream('utf-8', {
      path: S.profile_path
    });

    /* TAINT stream returned by `flamegraph_from_stream` apparently doesn't emit `close` events, so we
    chose another way to do it:
     */
    source.pipe(D.$split()).pipe(D.$collect()).pipe($(function(callgraph_lines) {
      var svg;
      svg = flamegraph(callgraph_lines, {
        type: 'cpuprofile'
      });
      FS.writeFileSync(S.flamegraph_path, svg);
      return handler();
    }));
    return null;
  };

  new_spin = function(n) {
    var R, count;
    count = n;
    R = function() {
      var x;
      count += -1;
      x = Math.sin(count);
      if (!(count <= 0)) {
        return R();
      }
    };
    return R;
  };

  this.read_piped = function(settings, handler) {
    var S, _, i, input, input_path, output, output_path, p, ref, ref1;
    S = new_settings(settings);
    input_path = O.inputs[S.size];
    if (input_path == null) {
      throw new Error("unknown input size " + (rpr(S.size)));
    }
    if ((ref = S.mode) !== 'sync' && ref !== 'async') {
      throw new Error("unknown mode " + (rpr(S.mode)));
    }
    output_path = '/dev/null';
    input = FS.createReadStream(input_path);
    output = FS.createWriteStream(output_path);
    p = input;
    p = p.pipe($split());
    p = p.pipe(through2.obj(function(data, encoding, callback) {
      if (S.t0 == null) {
        start_profile(S);
      }
      S.byte_count += data.length;
      S.item_count += +1;
      this.push(data);
      return callback();
    }));
    for (_ = i = 1, ref1 = S.n; i <= ref1; _ = i += +1) {
      if (S.mode === 'sync') {
        p = p.pipe(through2.obj(function(data, encoding, callback) {
          this.push(data);
          return callback();
        }));
      } else {
        p = p.pipe(through2.obj(function(data, encoding, callback) {
          return setImmediate((function(_this) {
            return function() {
              _this.push(data);
              return callback();
            };
          })(this));
        }));
      }
    }
    p = p.pipe($as_line());
    p = p.pipe(output);
    output.on('close', function() {
      return step(function*(resume) {
        yield stop_profile(S, resume);
        S.t1 = Date.now();
        report(S);
        yield write_flamegraph(S, resume);
        return handler();
      });
    });
    return null;
  };

  this.read_evented = function(settings, handler) {

    /* TAINT code duplication */
    var S, input, input_path, output, output_path, ref;
    S = new_settings(settings);
    input_path = O.inputs[S.size];
    if (input_path == null) {
      throw new Error("unknown input size " + (rpr(S.size)));
    }
    if ((ref = S.mode) !== 'sync' && ref !== 'async') {
      throw new Error("unknown mode " + (rpr(S.mode)));
    }
    output_path = '/dev/null';
    input = FS.createReadStream(input_path, {
      encoding: 'utf-8'
    });
    output = FS.createWriteStream(output_path);
    start_profile(S);
    output.on('close', function() {
      return step(function*(resume) {
        yield stop_profile(S, resume);
        S.t1 = Date.now();
        report(S);
        yield write_flamegraph(S, resume);
        return handler();
      });
    });
    input.on('data', function(chunk) {

      /* more or less correct, since file contents are in US-ASCII: */
      var i, len, line, line_idx, lines, results, spin;
      S.byte_count += chunk.length;

      /* TAINT not quite right, chunk might end with partial line */
      lines = chunk.split('\n');
      results = [];
      for (line_idx = i = 0, len = lines.length; i < len; line_idx = ++i) {
        line = lines[line_idx];
        S.item_count += +1;
        line += '\n';
        spin = new_spin(S.n);
        spin();
        results.push(output.write(line));
      }
      return results;
    });
    input.on('end', function() {
      return output.end();
    });
    return null;
  };

  this.read_with_pipestreams = function(settings, handler) {
    var S, _, i, input, input_path, output, output_path, p, ref, ref1;
    S = new_settings(settings);
    input_path = O.inputs[S.size];
    if (input_path == null) {
      throw new Error("unknown input size " + (rpr(S.size)));
    }
    if ((ref = S.mode) !== 'sync' && ref !== 'async') {
      throw new Error("unknown mode " + (rpr(S.mode)));
    }
    output_path = '/dev/null';
    input = PS.new_stream(input_path);
    output = FS.createWriteStream(output_path);
    p = input;
    p = p.pipe(PS.$(function(data, send) {
      if (S.t0 == null) {
        start_profile(S);
      }
      return send(data);
    }));
    p = p.pipe(PS.$split());
    p = p.pipe(PS.$(function(line, send) {

      /* TAINT stream already decoded, but if it is all US-ASCII, count should be ok */
      S.byte_count += line.length;
      return send(line);
    }));
    p = p.pipe(PS.$(function(line, send) {
      S.item_count += +1;
      return send(line);
    }));
    for (_ = i = 1, ref1 = S.n; i <= ref1; _ = i += +1) {
      if (S.mode === 'sync') {
        p = p.pipe(PS.$(function(data, send) {
          return send(data + '*');
        }));
      } else {

        /* ??? */
        p = p.pipe(PS.$(function(data, send) {
          return setImmediate((function(_this) {
            return function() {
              return send(data);
            };
          })(this));
        }));
      }
    }
    p = p.pipe(PS.$as_line());
    p = p.pipe(output);

    /* TAINT use PipeStreams method */
    output.on('close', function() {
      return step(function*(resume) {
        yield stop_profile(S, resume);
        S.t1 = Date.now();
        report(S);
        yield write_flamegraph(S, resume);
        return handler();
      });
    });

    /* TAINT should be done by PipeStreams */
    input.on('end', function() {
      return output.end();
    });
    return null;
  };

  this.main = function() {
    var flavors, modes, n_max, size, transform_counts;
    n_max = running_in_devtools ? 3 : 1;
    size = 'long';
    size = 'tiny';
    flavors = ['piped'];
    modes = ['sync'];
    transform_counts = [10, 20];
    step((function(_this) {
      return function*(resume) {
        var flavor, i, j, k, l, len, len1, len2, mode, n, ref, run;
        for (run = i = 1, ref = n_max; 1 <= ref ? i <= ref : i >= ref; run = 1 <= ref ? ++i : --i) {
          for (j = 0, len = flavors.length; j < len; j++) {
            flavor = flavors[j];
            for (k = 0, len1 = modes.length; k < len1; k++) {
              mode = modes[k];
              if (flavor === 'evented' && mode === 'async') {
                continue;
              }
              for (l = 0, len2 = transform_counts.length; l < len2; l++) {
                n = transform_counts[l];
                switch (flavor) {
                  case 'piped':
                    yield _this.read_piped({
                      n: n,
                      size: size,
                      mode: mode,
                      flavor: flavor
                    }, resume);
                    break;
                  case 'evented':
                    yield _this.read_evented({
                      n: n,
                      size: size,
                      mode: mode,
                      flavor: flavor
                    }, resume);
                    break;
                  case 'pipestreams':
                    yield _this.read_with_pipestreams({
                      n: n,
                      size: size,
                      mode: mode,
                      flavor: flavor
                    }, resume);
                }
              }
            }
          }
        }
        if (running_in_devtools) {
          setTimeout((function() {
            return help('ok');
          }), 1e6);
        }
        return null;
      };
    })(this));
    return null;
  };

  if (module.parent == null) {
    this.main();
  }

}).call(this);

//# sourceMappingURL=main.js.map
