// Generated by CoffeeScript 1.12.1
(function() {
  var CND, badge, debug, echo, exclude_events, format_float, format_integer, help, info, new_numeral, rpr, warn, whisper,
    slice = [].slice,
    indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'BASIC-STREAM-BENCHMARKS/PATCH-EVENT-EMITTER';

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  info = CND.get_logger('info', badge);

  help = CND.get_logger('help', badge);

  whisper = CND.get_logger('whisper', badge);

  echo = CND.echo.bind(CND);

  new_numeral = require('numeral');

  format_float = function(x) {
    return (new_numeral(x)).format('0,0.000');
  };

  format_integer = function(x) {
    return (new_numeral(x)).format('0,0');
  };

  this.patch_event_emitter = function(name, event_emitter, exclude) {
    var _emit;
    if (exclude == null) {
      exclude = null;
    }

    /* TAINT safeguard against applying multiple patches; re-use same method for all event emitters */
    _emit = event_emitter.emit.bind(event_emitter);
    event_emitter.emit = (function(_this) {
      return function() {
        var P, event_name;
        event_name = arguments[0], P = 2 <= arguments.length ? slice.call(arguments, 1) : [];
        _emit.apply(null, ['*', event_name].concat(slice.call(P)));
        _emit.apply(null, [event_name].concat(slice.call(P)));
        return null;
      };
    })(this);
    event_emitter.on('*', (function(_this) {
      return function() {
        var P, event_name;
        event_name = arguments[0], P = 2 <= arguments.length ? slice.call(arguments, 1) : [];
        if (!((exclude != null) && indexOf.call(exclude, event_name) >= 0)) {
          debug('33201', name + "/" + event_name);
        }
        return null;
      };
    })(this));
    return null;
  };

  exclude_events = ['data', 'drain', 'pipe', 'prefinish', 'readable', 'resume', 'unpipe'];

  this.patch_timer_etc = function(input, output) {
    var t0, t1;
    this.patch_event_emitter('input', input, exclude_events);
    this.patch_event_emitter('output', output, exclude_events);
    t0 = null;
    t1 = null;
    input.on('open', function() {
      return t0 = Date.now();
    });
    output.on('close', function() {
      var dts, dts_txt;
      t1 = Date.now();
      dts = (t1 - t0) / 1000;
      dts_txt = format_float(dts);
      return help(dts_txt + "s");
    });
    return null;
  };

}).call(this);

//# sourceMappingURL=patch-event-emitter.js.map
