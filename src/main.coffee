




############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'BASIC-STREAM-BENCHMARKS'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
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
  dts             = ( S.t1 - S.t0 ) / 1000
  bps             = S.byte_count / dts
  ips             = S.item_count / dts
  byte_count_txt  = format_integer S.byte_count
  item_count_txt  = format_integer S.item_count
  dts_txt         = format_float   dts
  bps_txt         = format_float   bps
  ips_txt         = format_float   ips
  help "#{dts_txt}s"
  help "#{byte_count_txt} bytes / #{item_count_txt} items"
  help "#{bps_txt} bps / #{ips_txt} ips"

#-----------------------------------------------------------------------------------------------------------
start_profile = ( run_name ) ->
  if running_in_devtools
    console.profile run_name
  else
    V8PROFILER.startProfiling run_name

#-----------------------------------------------------------------------------------------------------------
stop_profile = ( run_name, handler ) ->
  if running_in_devtools
    console.profileEnd run_name
  else
    step ( resume ) ->
      profile       = V8PROFILER.stopProfiling run_name
      profile_data  = yield profile.export resume
      FS.writeFileSync "profile-#{run_name}.json", profile_data
      handler()

#-----------------------------------------------------------------------------------------------------------
write_flamegraph = ( run_name, handler ) ->
  ###
  ###
  return if running_in_devtools
  profile_name    = "profile-#{run_name}.json"
  flamegraph_name = "flamegraph-#{run_name}.svg"
  # debug '33928', 'cat', [ profile_name, '|', 'flamegraph', '-t', 'cpuprofile', '>', flamegraph_name, ]
  source          = D.new_stream 'utf-8', { path: profile_name, }
  # output          = D.new_stream 'write', { path: flamegraph_name, }
  callgraph_lines = null
  ### TAINT stream returned by `flamegraph_from_stream` apparently doesn't emit `close` events, so we
  chose another way to do it: ###
  source
    .pipe D.$split()
    .pipe D.$collect()
    .pipe $ ( lines ) -> callgraph_lines = lines
    .pipe $ 'finish', ->
      svg = flamegraph callgraph_lines, { type: 'cpuprofile', }
      FS.writeFileSync flamegraph_name, svg
      handler()
  # input           = flamegraph_from_stream source, { type: 'cpuprofile', }
  # input.on 'end', -> debug 'end'
  # input.on 'close', -> debug 'close'
  # input
  #   .pipe output
  #   .pipe $ 'finish', ->
  #     debug '44321', run_name
  #     help "output written to #{flamegraph_name}"
  #     handler()
  return null


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
  S.byte_count  = 0
  S.item_count  = 0
  S.t0          = null
  S.t1          = null
  run_name      = "n=#{n},size=#{size},mode=#{mode}"
  #.........................................................................................................
  p = input
  p = p.pipe $split()
  #.........................................................................................................
  p = p.pipe through2.obj ( data, encoding, callback ) ->
    unless S.t0?
      start_profile run_name
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
      p = p.pipe through2.obj ( data, encoding, callback ) -> setImmediate => @push data; callback()
  #.........................................................................................................
  p = p.pipe $as_line()
  p = p.pipe output
  #.........................................................................................................
  output.on 'close', ->
    step ( resume ) ->
      yield stop_profile run_name, resume
      S.t1 = Date.now()
      report S
      yield write_flamegraph run_name, resume
      debug '88272'
      handler()
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@main = ->
  # size  = 'short'
  # size  = 'long'
  # mode        = 'async'
  # mode        = 'sync'
  n_max = if running_in_devtools then 3 else 1
  step ( resume ) =>
    for run in [ 1 .. n_max ]
      for mode in [ 'sync', 'async', ]
        for size in [ 'short', ]
          for n in [ 1, 10, 100, ]
            debug run, mode, size, n
            yield @read_with_transforms n, size, mode, resume
      # yield @read_with_transforms   0, size, mode, resume
      # yield @read_with_transforms   1, size, mode, resume
      # yield @read_with_transforms   5, size, mode, resume
      # yield @read_with_transforms  10, size, mode, resume
      # yield @read_with_transforms  50, size, mode, resume
      # yield @read_with_transforms 100, size, mode, resume
      # yield @read_with_transforms 200, size, mode, resume
      # yield @read_with_transforms 300, size, mode, resume
    if running_in_devtools
      setTimeout ( -> help 'ok' ), 1e6


############################################################################################################
unless module.parent?
  @main()










