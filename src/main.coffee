




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
      FS.writeFileSync S.profile_name, profile_data
      handler()

#-----------------------------------------------------------------------------------------------------------
write_flamegraph = ( S, handler ) ->
  return if running_in_devtools
  #.........................................................................................................
  S.flamegraph_name = "flamegraph-#{S.job_name}.svg"
  source            = D.new_stream 'utf-8', { path: S.profile_name, }
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


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@read_with_transforms = ( n, size, mode, handler ) ->
  # input_path  = PATH.resolve __dirname, '../test-data/Unicode-index.txt'
  input_path    = O.inputs[ size ]
  throw new Error "unknown input size #{rpr size}" unless input_path?
  throw new Error "unknown mode #{rpr mode}" unless mode in [ 'sync', 'async', ]
  output_path   = '/dev/null'
  input         = FS.createReadStream   input_path
  output        = FS.createWriteStream  output_path
  S             = {}
  S.n           = n
  S.size        = size
  S.mode        = mode
  S.byte_count  = 0
  S.item_count  = 0
  S.t0          = null
  S.t1          = null
  S.job_name    = "n=#{n},size=#{size},mode=#{mode}"
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


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@stupid_read = ( n, size, mode, handler ) ->
  # input_path  = PATH.resolve __dirname, '../test-data/Unicode-index.txt'
  input_path    = O.inputs[ size ]
  throw new Error "unknown input size #{rpr size}" unless input_path?
  throw new Error "unknown mode #{rpr mode}" unless mode in [ 'sync', 'async', ]
  output_path   = '/dev/null'
  S             = {}
  S.n           = n
  S.size        = size
  S.mode        = mode
  S.byte_count  = 0
  S.item_count  = 0
  S.t0          = null
  S.t1          = null
  S.job_name    = "flavor=stupid,n=#{n},size=#{size},mode=#{mode}"
  start_profile S
  input         = FS.readFileSync input_path, { encoding: 'utf-8', }
  output        = FS.createWriteStream output_path
  #.........................................................................................................
  output.on 'close', ->
    step ( resume ) ->
      yield stop_profile S, resume
      S.t1 = Date.now()
      report S
      # yield write_flamegraph S, resume
      handler()
  #.........................................................................................................
  lines = input.split '\n'
  #.........................................................................................................
  for line, line_idx in lines
    line += '\n'
    output.push line
  output.end()
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@main = ->
  n_max = if running_in_devtools then 3 else 1
  step ( resume ) =>
    for run in [ 1 .. n_max ]
      for size in [ 'short', 'long', ]
        for mode in [ 'sync', 'async', ]
          for n in [ 0, 1, 10, 20, 40, ]
            yield @read_with_transforms n, size, mode, resume
    if running_in_devtools
      setTimeout ( -> help 'ok' ), 1e6

#-----------------------------------------------------------------------------------------------------------
@stupid_main = ->
  n     = 10
  size  = 'long'
  mode  = 'sync'
  step ( resume ) =>
    @stupid_read n, size, mode, resume
  # n_max = if running_in_devtools then 3 else 1
  #   for run in [ 1 .. n_max ]
  #     for size in [ 'short', 'long', ]
  #       for mode in [ 'sync', 'async', ]
  #         for n in [ 0, 1, 10, 20, 40, ]
  #           yield @read_with_transforms n, size, mode, resume
  #   if running_in_devtools
  #     setTimeout ( -> help 'ok' ), 1e6


############################################################################################################
unless module.parent?
  # @main()
  @stupid_main()










