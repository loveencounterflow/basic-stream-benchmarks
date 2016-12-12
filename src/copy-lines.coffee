

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'BASIC-STREAM-BENCHMARKS/COPY-LINES'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
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
PATCHER                   = require './patch-event-emitter'

###
adapted from
https://strongloop.com/strongblog/practical-examples-of-the-new-node-js-streams-api/
###


# stream  = require 'stream'
stream  = require 'readable-stream'


#-----------------------------------------------------------------------------------------------------------
$split = ->
  #.........................................................................................................
  R         = new stream.Transform objectMode: true
  last_line = null
  #.........................................................................................................
  R._transform = ( chunk, encoding, done ) ->
    data = chunk.toString()
    if last_line?
      data = last_line + data
    lines = data.split '\n'
    last_line = ( lines.splice lines.length - 1, 1 )[ 0 ]
    lines.forEach @push.bind @
    done()
    return
  #.........................................................................................................
  R._flush = ( done ) ->
    if last_line?
      @push last_line
    last_line = null
    done()
    return
  #.........................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
$show = ->
  #.........................................................................................................
  R = new stream.Transform objectMode: true
  #.........................................................................................................
  R._transform = ( chunk, encoding, done ) ->
    @push chunk
    # debug '11021', chunk.length
    debug '11021', chunk
    done()
    return
  #.........................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
$pass = ->
  #.........................................................................................................
  R = new stream.Transform objectMode: true
  #.........................................................................................................
  R._transform = ( chunk, encoding, done ) ->
    @push chunk
    done()
    return
  #.........................................................................................................
  return R


#===========================================================================================================
mkdirp.sync PATH.dirname O.outputs.lines
settings        = null
# settings        = { highWaterMark: 16000, }
# settings        = { highWaterMark: 1e6, }
# input           = FS.createReadStream   O.inputs.tiny,    settings
input           = FS.createReadStream   O.inputs.long,    settings
output          = FS.createWriteStream  O.outputs.lines,  settings
PATCHER.patch_timer_etc input, output

x = input
x = x.pipe $split()
# for idx in [ 1 .. 100 ]
#   x = x.pipe $pass()
x = x.pipe output

