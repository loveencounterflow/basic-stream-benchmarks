


############################################################################################################
# njs_util                  = require 'util'
njs_path                  = require 'path'
# njs_fs                    = require 'fs'
#...........................................................................................................
TRM                       = require './TRM'
rpr                       = TRM.rpr.bind TRM
badge                     = 'BITSNPIECES/test'
log                       = TRM.get_logger 'plain',     badge
info                      = TRM.get_logger 'info',      badge
whisper                   = TRM.get_logger 'whisper',   badge
alert                     = TRM.get_logger 'alert',     badge
debug                     = TRM.get_logger 'debug',     badge
warn                      = TRM.get_logger 'warn',      badge
help                      = TRM.get_logger 'help',      badge
urge                      = TRM.get_logger 'urge',      badge
praise                    = TRM.get_logger 'praise',    badge
echo                      = TRM.echo.bind TRM
#...........................................................................................................
CND                       = require './main'
test                      = require 'guy-test'


# #-----------------------------------------------------------------------------------------------------------
# eq = ( P... ) =>
#   whisper P
#   # throw new Error "not equal: \n#{( ( rpr p ) for p in P ).join '\n'}" unless CND.equals P...
#   unless CND.equals P...
#     warn "not equal: \n#{( ( rpr p ) for p in P ).join '\n'}"
#     return 1
#   return 0

# #-----------------------------------------------------------------------------------------------------------
# @_test = ->
#   error_count = 0
#   for name, method of @
#     continue if name.startsWith '_'
#     whisper name
#     try
#       method()
#     catch error
#       # throw error
#       error_count += +1
#       warn error[ 'message' ]
#   help "tests completed successfully" if error_count is 0
#   process.exit error_count

#-----------------------------------------------------------------------------------------------------------
@[ "test type_of" ] = ( T ) ->
  T.eq ( CND.type_of new WeakMap()            ), 'weakmap'
  T.eq ( CND.type_of new Map()                ), 'map'
  T.eq ( CND.type_of new Set()                ), 'set'
  T.eq ( CND.type_of new Date()               ), 'date'
  T.eq ( CND.type_of new Error()              ), 'error'
  T.eq ( CND.type_of []                       ), 'list'
  T.eq ( CND.type_of true                     ), 'boolean'
  T.eq ( CND.type_of false                    ), 'boolean'
  T.eq ( CND.type_of ( -> )                   ), 'function'
  T.eq ( CND.type_of ( -> yield 123 )()       ), 'generator'
  T.eq ( CND.type_of null                     ), 'null'
  T.eq ( CND.type_of 'helo'                   ), 'text'
  T.eq ( CND.type_of undefined                ), 'undefined'
  T.eq ( CND.type_of arguments                ), 'arguments'
  T.eq ( CND.type_of global                   ), 'global'
  T.eq ( CND.type_of /^xxx$/g                 ), 'regex'
  T.eq ( CND.type_of {}                       ), 'pod'
  T.eq ( CND.type_of NaN                      ), 'nan'
  T.eq ( CND.type_of 1 / 0                    ), 'infinity'
  T.eq ( CND.type_of -1 / 0                   ), 'infinity'
  T.eq ( CND.type_of 12345                    ), 'number'
  T.eq ( CND.type_of new Buffer 'helo'        ), 'buffer'
  T.eq ( CND.type_of new ArrayBuffer 42       ), 'arraybuffer'
  #.........................................................................................................
  T.eq ( CND.type_of new Int8Array         5  ), 'int8array'
  T.eq ( CND.type_of new Uint8Array        5  ), 'uint8array'
  T.eq ( CND.type_of new Uint8ClampedArray 5  ), 'uint8clampedarray'
  T.eq ( CND.type_of new Int16Array        5  ), 'int16array'
  T.eq ( CND.type_of new Uint16Array       5  ), 'uint16array'
  T.eq ( CND.type_of new Int32Array        5  ), 'int32array'
  T.eq ( CND.type_of new Uint32Array       5  ), 'uint32array'
  T.eq ( CND.type_of new Float32Array      5  ), 'float32array'
  T.eq ( CND.type_of new Float64Array      5  ), 'float64array'
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "test size_of" ] = ( T ) ->
  # debug ( new Buffer '𣁬', ), ( '𣁬'.codePointAt 0 ).toString 16
  # debug ( new Buffer '𡉜', ), ( '𡉜'.codePointAt 0 ).toString 16
  # debug ( new Buffer '𠑹', ), ( '𠑹'.codePointAt 0 ).toString 16
  # debug ( new Buffer '𠅁', ), ( '𠅁'.codePointAt 0 ).toString 16
  T.eq ( CND.size_of [ 1, 2, 3, 4, ]                                    ), 4
  T.eq ( CND.size_of new Buffer [ 1, 2, 3, 4, ]                         ), 4
  T.eq ( CND.size_of '𣁬𡉜𠑹𠅁'                                             ), 2 * ( Array.from '𣁬𡉜𠑹𠅁' ).length
  T.eq ( CND.size_of '𣁬𡉜𠑹𠅁', count: 'codepoints'                        ), ( Array.from '𣁬𡉜𠑹𠅁' ).length
  T.eq ( CND.size_of '𣁬𡉜𠑹𠅁', count: 'codeunits'                         ), 2 * ( Array.from '𣁬𡉜𠑹𠅁' ).length
  T.eq ( CND.size_of '𣁬𡉜𠑹𠅁', count: 'bytes'                             ), ( new Buffer '𣁬𡉜𠑹𠅁', 'utf-8' ).length
  T.eq ( CND.size_of 'abcdefghijklmnopqrstuvwxyz'                       ), 26
  T.eq ( CND.size_of 'abcdefghijklmnopqrstuvwxyz', count: 'codepoints'  ), 26
  T.eq ( CND.size_of 'abcdefghijklmnopqrstuvwxyz', count: 'codeunits'   ), 26
  T.eq ( CND.size_of 'abcdefghijklmnopqrstuvwxyz', count: 'bytes'       ), 26
  T.eq ( CND.size_of 'ä'                                                ), 1
  T.eq ( CND.size_of 'ä', count: 'codepoints'                           ), 1
  T.eq ( CND.size_of 'ä', count: 'codeunits'                            ), 1
  T.eq ( CND.size_of 'ä', count: 'bytes'                                ), 2
  T.eq ( CND.size_of new Map [ [ 'foo', 42, ], [ 'bar', 108, ], ]       ), 2
  T.eq ( CND.size_of new Set [ 'foo', 42, 'bar', 108, ]                 ), 4
  T.eq ( CND.size_of { 'foo': 42, 'bar': 108, 'baz': 3, }                           ), 3
  T.eq ( CND.size_of { '~isa': 'XYZ/yadda', 'foo': 42, 'bar': 108, 'baz': 3, }      ), 4

#-----------------------------------------------------------------------------------------------------------
@[ "is_subset" ] = ( T ) ->
  T.eq false, CND.is_subset ( Array.from 'abcde' ), ( Array.from 'abcd' )
  T.eq false, CND.is_subset ( Array.from 'abcx'  ), ( Array.from 'abcd' )
  T.eq false, CND.is_subset ( Array.from 'abcd'  ), ( []                )
  T.eq true,  CND.is_subset ( Array.from 'abcd'  ), ( Array.from 'abcd' )
  T.eq true,  CND.is_subset ( Array.from 'abc'   ), ( Array.from 'abcd' )
  T.eq true,  CND.is_subset ( []                 ), ( Array.from 'abcd' )
  T.eq true,  CND.is_subset ( []                 ), ( Array.from []     )
  T.eq false, CND.is_subset ( new Set 'abcde'    ), ( new Set 'abcd'    )
  T.eq false, CND.is_subset ( new Set 'abcx'     ), ( new Set 'abcd'    )
  T.eq false, CND.is_subset ( new Set 'abcx'     ), ( new Set()         )
  T.eq true,  CND.is_subset ( new Set 'abcd'     ), ( new Set 'abcd'    )
  T.eq true,  CND.is_subset ( new Set 'abc'      ), ( new Set 'abcd'    )
  T.eq true,  CND.is_subset ( new Set()          ), ( new Set 'abcd'    )
  T.eq true,  CND.is_subset ( new Set()          ), ( new Set()         )
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "deep_copy" ] = ( T ) ->
  ### TAINT set comparison doesn't work ###
  probes = [
    [ 'foo', 42, [ 'bar', ( -> 'xxx' ), ], { q: 'Q', s: 'S', }, ]
    ]
  # probe   = [ 'foo', 42, [ 'bar', ( -> 'xxx' ), ], ( new Set Array.from 'abc' ), ]
  # matcher = [ 'foo', 42, [ 'bar', ( -> 'xxx' ), ], ( new Set Array.from 'abc' ), ]
  for probe in probes
    result  = CND.deep_copy probe
    T.eq result, probe
    T.ok result isnt probe
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "XJSON (1)" ] = ( T ) ->
  e         = new Set 'xy'
  e.add new Set 'abc'
  d         = [ 'A', 'B', e, ]
  T.eq (     CND.XJSON.stringify d                 ), """["A","B",{"~isa":"-x-set","%self":["x","y",{"~isa":"-x-set","%self":["a","b","c"]}]}]"""
  ### TAINT doing string comparison here to avoid implicit test that T.eq deals with sets correctly ###
  T.eq ( rpr CND.XJSON.parse CND.XJSON.stringify d ), """[ 'A', 'B', Set { 'x', 'y', Set { 'a', 'b', 'c' } } ]"""
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "XJSON (2)" ] = ( T ) ->
  s   = new Set Array.from 'Popular Mechanics'
  m   = new Map [ [ 'a', 1, ], [ 'b', 2, ], ]
  f   = ( x ) -> x ** 2
  d   = { s, m, f, }
  #.........................................................................................................
  d_json     = CND.XJSON.stringify d
  d_ng       = CND.XJSON.parse     d_json
  d_ng_json  = CND.XJSON.stringify d_ng
  T.eq d_json, d_ng_json
  #.........................................................................................................
  ### TAINT using T.eq directly on values, not their alternative serialization would implicitly test whether
  CND.equals accepts sets and maps ###
  T.eq ( rpr d_ng[ 's' ] ), ( rpr d[ 's' ] )
  T.eq ( rpr d_ng[ 'm' ] ), ( rpr d[ 'm' ] )
  T.eq d_ng[ 'f' ], d[ 'f' ]
  T.eq ( d_ng[ 'f' ] 12 ), ( d[ 'f' ] 12 )
  T.eq ( d_ng[ 'f' ] 12 ), 144
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "XJSON (3)" ] = ( T ) ->
  d =
    my_number:          42
    my_buffer:          Buffer.from     [ 127, 128, 129, ]
    my_null:            null
    my_nan:             NaN
    my_local_symbol:    Symbol    'local-symbol'
    my_global_symbol:   Symbol.for 'global-symbol'
    # my_arraybuffer:   new ArrayBuffer 3
  #.........................................................................................................
  d[ Symbol.for 'foo' ] = 'bar'
  d[ Symbol     'FOO' ] = 'BAR'
  #.........................................................................................................
  # help '01220', rpr d
  d_json  = CND.XJSON.stringify d
  d_ng    = CND.XJSON.parse d_json
  T.eq d_ng.my_number,        d.my_number
  T.eq d_ng.my_buffer,        d.my_buffer
  T.eq d_ng.my_null,          d.my_null
  T.eq d_ng.my_nan,           d.my_nan
  T.eq d_ng.my_global_symbol, d.my_global_symbol
  ### NOTE it's not possible to recreate the identity of a local symbol, so we check value and status: ###
  T.eq d_ng.my_local_symbol.toString(),  d.my_local_symbol.toString()
  d_ng_text = d_ng.my_local_symbol.toString().replace /^Symbol\((.*)\)$/, '$1'
  T.ok d.my_local_symbol isnt Symbol.for d_ng_text
  #.........................................................................................................
  return null


#===========================================================================================================
# MAIN
#-----------------------------------------------------------------------------------------------------------
@_main = ( handler ) ->
  test @, 'timeout': 2500

#-----------------------------------------------------------------------------------------------------------
@_prune = ->
  for name, value of @
    continue if name.startsWith '_'
    delete @[ name ] unless name in include
  return null

############################################################################################################
unless module.parent?
  include = [
    "test type_of"
    "test size_of"
    "is_subset"
    "deep_copy"
    "XJSON (1)"
    "XJSON (2)"
    "XJSON (3)"
    ]
  @_prune()
  @_main()

  # debug Object.keys @














