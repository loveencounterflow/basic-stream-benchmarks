




############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'BASIC-STREAM-BENCHMARKS'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
help                      = CND.get_logger 'help',      badge
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
@read_formula_data = ( handler ) ->
  # input_path  = PATH.resolve __dirname, '../test-data/Unicode-index.txt'
  input_path    = PATH.resolve __dirname, '../test-data/Unicode-NamesList.txt'
  output_path   = '/tmp/xxx.txt'
  input         = FS.createReadStream   input_path
  output        = FS.createWriteStream  output_path
  S             = {}
  S.byte_count  = 0
  S.item_count  = 0
  S.t0          = null
  S.t1          = null
  #.........................................................................................................
  input
    #.......................................................................................................
    .pipe $split()
    # .pipe $show()
    #.......................................................................................................
    .pipe through2.obj ( data, encoding, callback ) ->
      S.t0         ?= Date.now()
      S.byte_count += data.length
      S.item_count += +1
      @push data
      callback()
    #.......................................................................................................
    .pipe through2.obj ( data, encoding, callback ) -> @push data; callback()
    .pipe through2.obj ( data, encoding, callback ) -> @push data; callback()
    #.......................................................................................................
    .pipe $as_line()
    .pipe output
  #.........................................................................................................
  output.on 'close', =>
    S.t1 = Date.now()
    @report S
    handler()
  #.........................................................................................................
  return null

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
@read_formula_data_basic_version = ( handler ) ->
  path        = PATH.resolve __dirname, '../../../mingkwai-rack/jizura-datasources/data/flat-files/shape/shape-breakdown-formula.txt'
  input       = FS.createReadStream path
  output      = FS.createWriteStream '/tmp/xxx.txt'
  byte_count  = 0
  item_count  = 0
  t0          = null
  t1          = null
  #.........................................................................................................
  output.on 'finish', =>
    help "finished"
    handler()
  #.........................................................................................................
  input
    # .pipe $ 'start', ( send ) => t0 = Date.now()
    # .pipe $ ( chunk ) => byte_count += chunk.length
    #.......................................................................................................
    .pipe $split()
    .pipe through2.obj ( data, encoding, callback ) -> @push data; callback()
    .pipe through2.obj ( data, encoding, callback ) -> @push data; callback()
    .pipe through2.obj ( data, encoding, callback ) -> @push data; callback()
    # .pipe $ ( data, send ) => send data # nr 1
    # .pipe $ ( data, send ) => send data # nr 2
    # .pipe $ ( data, send ) => send data # nr 3
    # .pipe $ ( data, send ) => send data # nr 4
    # .pipe $ ( data, send ) => send data # nr 5
    # .pipe $ ( data, send ) => send data # nr 6
    # .pipe $ ( data, send ) => send data # nr 7
    # #.......................................................................................................
    # .pipe $ ( data ) =>
    #   item_count += +1
    #   # whisper item_count if item_count % 100 is 0
    # #.......................................................................................................
    # .pipe $ ( data, send ) => send "item_count: #{item_count}, byte_count: #{byte_count}\n"
    # .pipe $ 'stop', ( send ) -> t1 = Date.now()
    .pipe output
    #.......................................................................................................
    .pipe $ 'finish', =>
      t1              = Date.now()
      dts             = ( t1 - t0 ) / 1000
      bps             =  byte_count / dts
      ips             =  item_count / dts
      byte_count_txt  = format_integer  byte_count
      item_count_txt  = format_integer  item_count
      dts_txt         = format_float dts
      bps_txt         = format_float bps
      ips_txt         = format_float ips
      help "#{dts_txt}s"
      help "#{byte_count_txt} bytes / #{item_count_txt} items"
      help "#{bps_txt} bps / #{ips_txt} ips"
      handler()
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@run_devtools_example = ->
  console.profile 'build'
  count = 0
  f = ->
    urge "item ##{count}"
    count += +1
    if count < 1000
      setImmediate -> f()
    else
      console.profileEnd 'build'
  f()
  setTimeout ( -> f() ), 1e6

#-----------------------------------------------------------------------------------------------------------
@test_1 = ->
  @read_formula_data ( error ) ->
    throw error if error?
    help 'ok'



############################################################################################################
console.profile    ?= ( name ) -> warn 'profile',     name
console.profileEnd ?= ( name ) -> warn 'profileEnd',  name


############################################################################################################
unless module.parent?
  @test_1()
  # @test_2()
  # @test_3()

###
make plan to base future major version of PipeDreams directly on https://github.com/nodejs/readable-stream
(and through2 etc)

ways to solve current problem without rewriting PipeDreams:

(1) try to read many sources in parallel
(2) collect entire file content into single string / buffer; sizes are all OK for that
(3) re-use existing pipeline for all files, only reset state

use both approaches at the same time

###












