

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

### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  ###
###  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # ###

# ```
# function logger () {
#   return function (read) {
#     debug( '22201', read );
#     read(null, function next(end, data) {
#       if(end === true) return
#       if(end) throw end
#       help( '20001', data )
#       read(null, next)
#     })
#   }
# }
# ```

logger = ->
  return ( read ) ->
    debug '22201', read
    next = ( end, data ) ->
      urge '20001', [ end, data, ]
      return if end is true
      throw end if end?
      read null, next
    read null, next
    return null

### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  ###
###  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # ###

```
function map( read, map ) {
  //return a readable function!
  return function ( end, handler ) {
    read(end, function (end, data) {
      debug( '33344', data );
      handler(end, data != null ? map(data) : null)
    })
  }
}
```


map = (read, map) ->
  #return a readable function!
  (end, handler) ->
    read end, (end, data) ->
      debug '33344', data
      handler end, if data != null then map(data) else null
      return
    return

  # map paths

### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  ###
###  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # ###

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

### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  ###
###  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # ###

pipeline = [
  # ( pull.values paths                                   )
  # ( pull.asyncMap FS.stat                               )
  # ( logger() )
  ( pull.values [ 1, 2, 3, ] )
  ( through ( data ) -> help data; @queue data; urge ( name for name of @ ) )
  ( pull.collect ( error, collector ) -> info collector )
  ]

pull pipeline...


```
pull(
  pull.values([1,2,3]),
  through(function (data) {
    this.queue(data * 10)
  }),
  pull.collect(function (err, ary) {
    if(err) throw err
    debug( ary );
    // t.deepEqual(ary, [10, 20, 30])
    // t.end()
  })
)
```

pipeline = [
  ( pull.values [ 1, 2, 3, ] )
  ( through ( data ) -> debug data; @queue data * 10 )
  ( pull.collect ( error, collector ) -> throw error if error?; debug collector )
  ]
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

