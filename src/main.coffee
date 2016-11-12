




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
@report = ( S ) ->
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
running_in_devtools = console.profile?

#-----------------------------------------------------------------------------------------------------------
start_profile = ( name ) ->
  if running_in_devtools then console.profile name
  else                        whisper 'console.profile', name

#-----------------------------------------------------------------------------------------------------------
stop_profile = ( name ) ->
  if running_in_devtools then console.profileEnd name
  else                        whisper 'console.profileEnd', name


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@read_with_transforms = ( n, input_name, mode, handler ) ->
  # input_path  = PATH.resolve __dirname, '../test-data/Unicode-index.txt'
  input_path    = O.inputs[ input_name ]
  throw new Error "unknown input name #{rpr input_name}" unless input_path?
  throw new Error "unknown mode #{rpr mode}" unless mode in [ 'sync', 'async', ]
  output_path   = '/dev/null'
  input         = FS.createReadStream   input_path
  output        = FS.createWriteStream  output_path
  S             = {}
  S.byte_count  = 0
  S.item_count  = 0
  S.t0          = null
  S.t1          = null
  name          = "n:#{n}"
  #.........................................................................................................
  p = input
  p = p.pipe $split()
  #.........................................................................................................
  p = p.pipe through2.obj ( data, encoding, callback ) ->
    unless S.t0?
      start_profile name
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
  output.on 'close', =>
    stop_profile name
    S.t1 = Date.now()
    @report S
    handler()
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@main = ->
  input_name  = 'short'
  # input_name  = 'long'
  mode        = 'async'
  # mode        = 'sync'
  step ( resume ) =>
    for run in [ 1 .. 1 ]
      yield @read_with_transforms   0, input_name, mode, resume
      # yield @read_with_transforms   5, input_name, mode, resume
      # yield @read_with_transforms  10, input_name, mode, resume
      # yield @read_with_transforms  50, input_name, mode, resume
      yield @read_with_transforms 100, input_name, mode, resume
      yield @read_with_transforms 200, input_name, mode, resume
      yield @read_with_transforms 300, input_name, mode, resume
    if running_in_devtools
      setTimeout ( -> help 'ok' ), 1e6


############################################################################################################
unless module.parent?
  @main()










