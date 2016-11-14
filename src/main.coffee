




############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'BASIC-STREAM-BENCHMARKS'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
PATH                      = require 'path'
FS                        = require 'fs'
#...........................................................................................................
through2                  = require 'through2'
$split                    = require 'binary-split'
#...........................................................................................................
new_numeral               = require 'numeral'
format_float              = ( x ) -> ( new_numeral x ).format '0,0.000'
format_integer            = ( x ) -> ( new_numeral x ).format '0,0'
{ step, }                 = require 'coffeenode-suspend'
#...........................................................................................................
O                         = {}
O.inputs                  = {}
O.inputs[ 'long' ]        = PATH.resolve __dirname, '../test-data/Unicode-NamesList.txt'
O.inputs[ 'short' ]       = PATH.resolve __dirname, '../test-data/Unicode-NamesList-short.txt'
#...........................................................................................................
D                         = require 'pipedreams'
{ $, $async, }            = D
#...........................................................................................................
### Avoid to try to require `v8-profiler` when running this module with `devtool`: ###
running_in_devtools       = console.profile?
V8PROFILER                = if running_in_devtools then null else require 'v8-profiler'
flamegraph                = require 'flamegraph'
flamegraph_from_stream    = require 'flamegraph/from-stream'


#===========================================================================================================
# HELPERS
#-----------------------------------------------------------------------------------------------------------
$show = ->
  return through2 ( data, encoding, callback ) ->
    # info rpr data
    @push data
    callback()

#-----------------------------------------------------------------------------------------------------------
$as_line = ->
  return through2 ( data, encoding, callback ) ->
    # info rpr data
    @push data + '\n'
    callback()

#-----------------------------------------------------------------------------------------------------------
report = ( S ) ->
  format_integer  = ( x ) -> "#{x}"
  format_float    = ( x ) -> x.toFixed 3
  dts             = ( S.t1 - S.t0 ) / 1000
  bps             = S.byte_count / dts
  ips             = S.item_count / dts
  byte_count_txt  = format_integer S.byte_count
  item_count_txt  = format_integer S.item_count
  dts_txt         = format_float   dts
  bps_txt         = format_float   bps
  ips_txt         = format_float   ips
  line            = []
  #.........................................................................................................
  if report.is_first
    report.is_first   = no
    echo CND.lime [ 'job', 'n', 'mode', 'dt', 'bytes', 'items', 'bps', 'ips', ].join '\t'
  #.........................................................................................................
  line.push S.job_name
  line.push S.n
  line.push S.mode
  line.push dts_txt
  line.push byte_count_txt
  line.push item_count_txt
  line.push bps_txt
  line.push ips_txt
  echo CND.steel line.join '\t'
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
report.is_first = yes

#-----------------------------------------------------------------------------------------------------------
start_profile = ( S ) ->
  if running_in_devtools
    console.profile S.job_name
  else
    V8PROFILER.startProfiling S.job_name

#-----------------------------------------------------------------------------------------------------------
stop_profile = ( S, handler ) ->
  if running_in_devtools
    console.profileEnd S.job_name
  else
    step ( resume ) ->
      profile         = V8PROFILER.stopProfiling S.job_name
      profile_data    = yield profile.export resume
      S.profile_name  = "profile-#{S.job_name}.json"
      profile_path    = PATH.resolve __dirname, '../profiles', S.profile_name
      FS.writeFileSync S.profile_path, profile_data
      handler()

#-----------------------------------------------------------------------------------------------------------
write_flamegraph = ( S, handler ) ->
  return if running_in_devtools
  #.........................................................................................................
  S.flamegraph_name = "flamegraph-#{S.job_name}.svg"
  flamegraph_path   = PATH.resolve __dirname, '../flamegraphs', S.flamegraph_name
  source            = D.new_stream 'utf-8', { path: flamegraph_path, }
  callgraph_lines   = null
  #.........................................................................................................
  ### TAINT stream returned by `flamegraph_from_stream` apparently doesn't emit `close` events, so we
  chose another way to do it: ###
  source
    .pipe D.$split()
    .pipe D.$collect()
    .pipe $ ( lines ) -> callgraph_lines = lines
    .pipe $ 'finish', ->
      svg = flamegraph callgraph_lines, { type: 'cpuprofile', }
      FS.writeFileSync S.flamegraph_name, svg
      handler()
  return null
  #.........................................................................................................
  # output          = D.new_stream 'write', { path: S.flamegraph_name, }
  # input           = flamegraph_from_stream source, { type: 'cpuprofile', }
  # input.on 'end', -> debug 'end'
  # input.on 'close', -> debug 'close'
  # input
  #   .pipe output
  #   .pipe $ 'finish', ->
  #     debug '44321', S.job_name
  #     help "output written to #{S.flamegraph_name}"
  #     handler()

#-----------------------------------------------------------------------------------------------------------
new_spin = ( n ) ->
  count = n
  R = ->
    count += -1
    x = Math.sin count
    R() unless count <= 0
  return R


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@read_piped = ( settings, handler ) ->
  ### TAINT code duplication ###
  S             = Object.assign {}, settings
  S.byte_count  = 0
  S.item_count  = 0
  S.t0          = null
  S.t1          = null
  S.job_name    = "#{S.flavor},#{S.n},#{S.size},#{S.mode}"
  input_path    = O.inputs[ S.size ]
  throw new Error "unknown input size #{rpr S.size}" unless input_path?
  throw new Error "unknown mode #{rpr S.mode}" unless S.mode in [ 'sync', 'async', ]
  output_path   = '/dev/null'
  input         = FS.createReadStream   input_path
  output        = FS.createWriteStream  output_path
  #.........................................................................................................
  p = input
  p = p.pipe $split()
  #.........................................................................................................
  p = p.pipe through2.obj ( data, encoding, callback ) ->
    unless S.t0?
      start_profile S
      S.t0 ?= Date.now()
    S.byte_count += data.length
    S.item_count += +1
    @push data
    callback()
  #.........................................................................................................
  for _ in [ 1 .. n ] by +1
    if mode is 'sync'
      p = p.pipe through2.obj ( data, encoding, callback ) -> @push data; callback()
    else
      # p = p.pipe through2.obj ( data, encoding, callback ) -> setImmediate => @push data; setImmediate => callback()
      p = p.pipe through2.obj ( data, encoding, callback ) -> setImmediate => @push data; callback()
  #.........................................................................................................
  p = p.pipe $as_line()
  p = p.pipe output
  #.........................................................................................................
  output.on 'close', ->
    step ( resume ) ->
      yield stop_profile S, resume
      S.t1 = Date.now()
      report S
      yield write_flamegraph S, resume
      handler()
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@read_evented = ( settings, handler ) ->
  ### TAINT code duplication ###
  S             = Object.assign {}, settings
  S.byte_count  = 0
  S.item_count  = 0
  S.t0          = null
  S.t1          = null
  S.job_name    = "#{S.flavor},#{S.n},#{S.size},#{S.mode}"
  input_path    = O.inputs[ S.size ]
  throw new Error "unknown input size #{rpr S.size}" unless input_path?
  throw new Error "unknown mode #{rpr S.mode}" unless S.mode in [ 'sync', 'async', ]
  # output_path   = '/dev/null'
  output_path   = '/tmp/xxx.txt'
  input         = FS.createReadStream   input_path, { encoding: 'utf-8', }
  output        = FS.createWriteStream output_path
  #.........................................................................................................
  start_profile S
  #.........................................................................................................
  output.on 'close', ->
    step ( resume ) ->
      yield stop_profile S, resume
      S.t1 = Date.now()
      report S
      yield write_flamegraph S, resume
      handler()
  #.........................................................................................................
  input.on 'data', ( chunk ) ->
    ### TAINT not quite right, chunk might end with partial line ###
    S.t0         ?= Date.now()
    ### more or less correct, since file contents are in US-ASCII: ###
    S.byte_count += chunk.length
    lines         = chunk.split '\n'
    #.......................................................................................................
    for line, line_idx in lines
      S.item_count += +1
      line += '\n'
      spin = new_spin S.n
      spin()
      output.write line
  #.........................................................................................................
  input.on 'end', ->
    output.end()
  #.........................................................................................................
  return null


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@main = ->
  n_max             = if running_in_devtools then 3 else 1
  size              = 'long'
  flavors           = [ 'evented', 'piped', ]
  # transform_counts  = [ 0, 1, 10, 20, 40, ]
  transform_counts  = [ 0, 1, ]
  modes             = [ 'sync', 'async', ]
  #.........................................................................................................
  step ( resume ) =>
    for run in [ 1 .. n_max ]
      for flavor in flavors
        for mode in modes
          for n in transform_counts
            if flavor is 'piped' then yield @read_piped   { n, size, mode, flavor, }, resume
            else                      yield @read_evented { n, size, mode, flavor, }, resume
    if running_in_devtools
      setTimeout ( -> help 'ok' ), 1e6
    return null
  #.........................................................................................................
  return null


############################################################################################################
unless module.parent?
  CND.run =>
    @main()










