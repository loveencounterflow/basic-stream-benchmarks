

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'BASIC-STREAM-BENCHMARKS/COPY-LINES'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
PATH                      = require 'path'
FS                        = require 'fs'
# OS                        = require 'os'
#...........................................................................................................
through2                  = require 'through2'
$split                    = require 'binary-split'
#...........................................................................................................
O                         = {}
O.inputs                  = {}
O.outputs                 = {}
O.inputs.long             = PATH.resolve __dirname, '../test-data/Unicode-NamesList.txt'
O.inputs.short            = PATH.resolve __dirname, '../test-data/Unicode-NamesList-short.txt'
O.inputs.tiny             = PATH.resolve __dirname, '../test-data/Unicode-NamesList-tiny.txt'
O.outputs.lines           = PATH.resolve __dirname, '/tmp/basic-stream-benchmarks/lines.txt'
#...........................................................................................................
new_numeral               = require 'numeral'
format_float              = ( x ) -> ( new_numeral x ).format '0,0.000'
format_integer            = ( x ) -> ( new_numeral x ).format '0,0'
#...........................................................................................................
mkdirp                    = require 'mkdirp'
# PATCHER                   = require './patch-event-emitter'
pull                      = require 'pull-stream'
$split                    = require 'pull-split'
# stream  = require 'readable-stream'
through                   = require 'pull-through'


### https://github.com/dominictarr/pull-stream-examples/blob/master/compose.js ###
parseCsv = ->
  return pull $split(), pull.map ( line ) ->
    return line.split /,\s+/

paths = [
  PATH.resolve __dirname, './copy-lines.js'
  PATH.resolve __dirname, './copy-lines-with-pull-stream.js'
  PATH.resolve __dirname, './main.js'
  PATH.resolve __dirname, './patch-event-emitter.js'
  ]



### http://dominictarr.com/post/149248845122/pull-streams-pull-streams-are-a-very-simple ###

```
function values(array) {
  var i = 0
  return function (abort, cb) {
    if(abort) return cb(abort)
    return cb(i >= array.length ? true : null, array[i++])
  }
}
```

#-----------------------------------------------------------------------------------------------------------
values = ( list ) ->
  ### source ###
  idx = 0
  return ( end, handler ) ->
    return handler end if end
    return handler true  if idx >= list.length
    idx += +1
    handler null, list[ idx - 1 ]

#-----------------------------------------------------------------------------------------------------------
$random = ( n ) ->
  ### source ###
  return ( end, handler ) ->
    return handler end if end
    ### only read n times, then stop ###
    n += -1
    return handler true if n < 0
    handler null, Math.random()

#-----------------------------------------------------------------------------------------------------------
$sequence = ( n ) ->
  ### source ###
  Z = 0
  return ( end, handler ) ->
    return handler end if end
    Z += +1
    return handler true if Z > n
    handler null, Z

#-----------------------------------------------------------------------------------------------------------
$logger = ->
  ### sink ###
  return ( read ) ->
    next = ( end, data ) ->
      return if end is true
      throw end if end
      info '>>>', data
      read null, next
    read null, next
    return null

# #-----------------------------------------------------------------------------------------------------------
# $map = ( read, map ) ->
#   ### return a readable function! ###
#   return ( end, handler ) ->
#     read end, ( end, data ) ->
#       Z = if data? then map data else null
#       handler end, Z
#       return
#     return


#-----------------------------------------------------------------------------------------------------------
prop = require 'pull-stream/util/prop'

id = ( e ) -> e

$map = ( mapper ) ->
  debug '22201', mapper
  return id unless mapper?
  mapper = prop mapper
  return ( read ) ->
    return ( abort, handler ) ->
      read abort, ( end, data ) ->
        debug '23201', data
        try
          data = if not end then mapper data else null
        catch error
          return read error, -> handler error
        handler end, data
        return
      return


### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  ###
###  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # ###

  # ( pull.values paths                                   )
  # ( pull.asyncMap FS.stat                               )
  # ( pull.values [ 1, 2, 3, ] )
  # ( values [ 1, 2, 3, ] )

#===========================================================================================================
pipeline = [
  # ( $random 4 )
  ( $sequence 4 )
  ( $map ( data ) -> whisper '+++', data; data ** 2 )
  ( through ( data ) -> whisper '###', data; @queue data )
  # ( pull.collect ( error, collector ) -> info collector; @queue collector )
  ( $logger() )
  ]

pull pipeline...
$logger() $random 5

#===========================================================================================================
pipeline = [
  ( pull.values [ 1, 2, 3, ] )
  ( through ( data ) -> @queue data * 10 )
  ( pull.collect ( error, collector ) -> throw error if error?; debug '***', collector )
  ]
pull pipeline...



#===========================================================================================================
$stringify                = require 'pull-stringify'
$split                    = require 'pull-split'
$utf8                     = require 'pull-utf8-decoder'
$on_end                   = require 'pull-stream/sinks/on-end'
to_pull                   = require 'stream-to-pull-stream'
input_stream              = FS.createReadStream PATH.resolve __dirname, '../test-data/ids.txt'
# output                    = process.stdout
output_stream             = FS.createWriteStream '/tmp/formulas.txt'

pipeline  = []
push      = pipeline.push.bind pipeline

#-----------------------------------------------------------------------------------------------------------
t0        = null
t1        = null
count     = 0

#...........................................................................................................
$input = -> to_pull.source input_stream

#...........................................................................................................
$output = ->
  return to_pull.sink output_stream, ( error ) ->
    throw error if error?
    t1  = Date.now()
    dts = ( t1 - t0 ) / 1000
    ips = count / dts
    help "dts: #{format_float dts}, ips: #{format_float ips}"
    help 'ok'

#...........................................................................................................
$stop_time = ->
  return through do ->
    is_first = yes
    return ( data ) ->
      if is_first
        is_first  = no
        t0        = Date.now()
      @queue data
      return null

#-----------------------------------------------------------------------------------------------------------
push $input()
push $stop_time()
push $utf8()
push $split()
push pull.map      ( line    ) -> count += +1; return line
push pull.map      ( line    ) -> line.trim()
push pull.filter   ( line    ) -> line.length > 0
push pull.filter   ( line    ) -> not line.startsWith '#'
# push pull.filter   ( line    ) -> ( /魚/ ).test line
push pull.map      ( line    ) -> line.split '\t'
push pull.map      ( fields  ) -> [ _, glyph, formula, ] = fields; return [ glyph, formula, ]
push pull.map      ( fields  ) -> JSON.stringify fields
push pull.map      ( line    ) -> line + '\n'
push $output()

#-----------------------------------------------------------------------------------------------------------
pull pipeline...


# #-----------------------------------------------------------------------------------------------------------
# $pass = ->
#   #.........................................................................................................
#   R = new stream.Transform objectMode: true
#   #.........................................................................................................
#   R._transform = ( chunk, encoding, done ) ->
#     @push chunk
#     done()
#     return
#   #.........................................................................................................
#   return R


# #===========================================================================================================
# mkdirp.sync PATH.dirname O.outputs.lines
# settings        = null
# # settings        = { highWaterMark: 16000, }
# # settings        = { highWaterMark: 1e6, }
# # input           = FS.createReadStream   O.inputs.tiny,    settings
# input           = FS.createReadStream   O.inputs.long,    settings
# output          = FS.createWriteStream  O.outputs.lines,  settings
# PATCHER.patch_timer_etc input, output

# x = input
# x = x.pipe $split()
# # for idx in [ 1 .. 100 ]
# #   x = x.pipe $pass()
# x = x.pipe output

