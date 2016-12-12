




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
OS                        = require 'os'
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
O.inputs[ 'long'  ]       = PATH.resolve __dirname, '../test-data/Unicode-NamesList.txt'
O.inputs[ 'short' ]       = PATH.resolve __dirname, '../test-data/Unicode-NamesList-short.txt'
O.inputs[ 'tiny'  ]       = PATH.resolve __dirname, '../test-data/Unicode-NamesList-tiny.txt'
#...........................................................................................................
D                         = require 'pipedreams'
{ $, $async, }            = D
### TAINT use installed version of PipeStreams ###
PS                        = require '../../pipestreams'
# PS                        = require 'pipestreams'
#...........................................................................................................
### Avoid to try to require `v8-profiler` when running this module with `devtool`: ###
running_in_devtools       = console.profile?
V8PROFILER                = null
unless running_in_devtools
  try
    V8PROFILER = require 'v8-profiler'
  catch error
    throw error unless error[ 'code' ] is 'MODULE_NOT_FOUND'
    warn "unable to `require v8-profiler`"
#...........................................................................................................
flamegraph                = require 'flamegraph'
flamegraph_from_stream    = require 'flamegraph/from-stream'
mkdirp                    = require 'mkdirp'


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
get_fingerprint = ->
  cpu_nfo = OS.cpus()[ 0 ]
  R = cpu_nfo[ 'model' ]
  R = R.toLowerCase()
  R = R.replace /[^-a-z0-9]/g,'-'
  R = R.replace /-+/g, '-'
  R = R.replace /^-/, ''
  R = R.replace /-$/, ''
  # speed   = "#{cpu_nfo[ 'speed' ]}mhz"
  # return "#{speed}-#{model}"
  return R

#-----------------------------------------------------------------------------------------------------------
new_settings = ( settings ) ->
  R             = Object.assign {}, settings
  R.byte_count  = 0
  R.item_count  = 0
  R.t0          = null
  R.t1          = null
  R.fingerprint = get_fingerprint()
  # R.speed       = R.fingerprint.replace /^([^-]+).*$/, '$1'
  R.job_name    = "#{R.fingerprint},#{R.flavor},#{R.n},#{R.mode}"
  return R

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
  S.t0 = Date.now()
  if running_in_devtools
    console.profile S.job_name
  else if V8PROFILER?
    V8PROFILER.startProfiling S.job_name

#-----------------------------------------------------------------------------------------------------------
stop_profile = ( S, handler ) ->
  if running_in_devtools
    console.profileEnd S.job_name
  else if V8PROFILER?
    step ( resume ) ->
      profile         = V8PROFILER.stopProfiling S.job_name
      profile_data    = yield profile.export resume
      S.profile_name  = "profile-#{S.job_name}.json"
      S.profile_home  = PATH.resolve __dirname, '../results', S.fingerprint, 'profiles'
      mkdirp.sync S.profile_home
      S.profile_path  = PATH.resolve S.profile_home, S.profile_name
      FS.writeFileSync S.profile_path, profile_data
      handler()

#-----------------------------------------------------------------------------------------------------------
write_flamegraph = ( S, handler ) ->
  return if running_in_devtools
  #.........................................................................................................
  S.flamegraph_name = "flamegraph-#{S.job_name}.svg"
  S.flamegraph_home = PATH.resolve __dirname, '../results', S.fingerprint, 'flamegraphs'
  mkdirp.sync S.flamegraph_home
  S.flamegraph_path = PATH.resolve S.flamegraph_home, S.flamegraph_name
  source            = D.new_stream 'utf-8', { path: S.profile_path, }
  #.........................................................................................................
  ### TAINT stream returned by `flamegraph_from_stream` apparently doesn't emit `close` events, so we
  chose another way to do it: ###
  source
    .pipe D.$split()
    .pipe D.$collect()
    .pipe $ ( callgraph_lines ) ->
      svg = flamegraph callgraph_lines, { type: 'cpuprofile', }
      FS.writeFileSync S.flamegraph_path, svg
      handler()
  return null

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
  S             = new_settings settings
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
    start_profile S unless S.t0?
    S.byte_count += data.length
    S.item_count += +1
    @push data
    callback()
  #.........................................................................................................
  for _ in [ 1 .. S.n ] by +1
    if S.mode is 'sync'
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
  S             = new_settings settings
  input_path    = O.inputs[ S.size ]
  throw new Error "unknown input size #{rpr S.size}" unless input_path?
  throw new Error "unknown mode #{rpr S.mode}" unless S.mode in [ 'sync', 'async', ]
  output_path   = '/dev/null'
  # output_path   = '/tmp/xxx.txt'
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
    ### more or less correct, since file contents are in US-ASCII: ###
    S.byte_count += chunk.length
    ### TAINT not quite right, chunk might end with partial line ###
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

#-----------------------------------------------------------------------------------------------------------
@read_with_pipestreams = ( settings, handler ) ->
  S             = new_settings settings
  input_path    = O.inputs[ S.size ]
  throw new Error "unknown input size #{rpr S.size}" unless input_path?
  throw new Error "unknown mode #{rpr S.mode}" unless S.mode in [ 'sync', 'async', ]
  output_path   = '/dev/null'
  # output_path   = '/tmp/output.txt'
  input         = PS.new_stream input_path
  output        = FS.createWriteStream output_path
  p             = input
  #.........................................................................................................
  p             = p.pipe PS.$ ( data, send ) ->
    start_profile S unless S.t0?
    send data
  p             = p.pipe PS.$split()
  #.........................................................................................................
  p             = p.pipe PS.$ ( line, send ) ->
    ### TAINT stream already decoded, but if it is all US-ASCII, count should be ok ###
    S.byte_count += line.length
    send line
  # p             = p.pipe PS.$show()
  #.........................................................................................................
  p             = p.pipe PS.$ ( line, send ) ->
    S.item_count += +1
    send line
  #.........................................................................................................
  for _ in [ 1 .. S.n ] by +1
    if S.mode is 'sync'
      p = p.pipe PS.$ ( data, send ) -> send data + '*'
    else
      ### ??? ###
      p = p.pipe PS.$ ( data, send ) -> setImmediate => send data
  p             = p.pipe PS.$as_line()
  p             = p.pipe output
  #.........................................................................................................
  ### TAINT use PipeStreams method ###
  output.on 'close', ->
    step ( resume ) ->
      yield stop_profile S, resume
      S.t1 = Date.now()
      report S
      yield write_flamegraph S, resume
      handler()
  #.........................................................................................................
  ### TAINT should be done by PipeStreams ###
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
  # size              = 'short'
  size              = 'tiny'
  #.........................................................................................................
  flavors           = [ 'pipestreams', ]
  modes             = [ 'sync', ]
  transform_counts  = [ 10, 20, ]
  #.........................................................................................................
  # flavors           = [ 'evented', 'piped', 'pipestreams', ]
  # transform_counts  = [ 0, 1, 10, 20, 40, 80, 160, ]
  # modes             = [ 'sync', 'async', ]
  #.........................................................................................................
  step ( resume ) =>
    for run in [ 1 .. n_max ]
      for flavor in flavors
        for mode in modes
          continue if flavor is 'evented' and mode is 'async'
          for n in transform_counts
            # debug '44339', { n, size, mode, flavor, }
            switch flavor
              when 'piped'        then yield @read_piped            { n, size, mode, flavor, }, resume
              when 'evented'      then yield @read_evented          { n, size, mode, flavor, }, resume
              when 'pipestreams'  then yield @read_with_pipestreams { n, size, mode, flavor, }, resume
    if running_in_devtools
      setTimeout ( -> help 'ok' ), 1e6
    return null
  #.........................................................................................................
  return null


############################################################################################################
unless module.parent?
  # CND.run => @main()
  @main()









