

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
{ step, }                 = require 'coffeenode-suspend'
#...........................................................................................................
O                         = {}
O.inputs                  = {}
O.outputs                 = {}
O.inputs.long             = PATH.resolve __dirname, '../test-data/Unicode-NamesList.txt'
O.inputs.short            = PATH.resolve __dirname, '../test-data/Unicode-NamesList-short.txt'
O.inputs.tiny             = PATH.resolve __dirname, '../test-data/Unicode-NamesList-tiny.txt'
O.outputs.lines           = PATH.resolve __dirname, '/tmp/basic-stream-benchmarks/lines.txt'
#...........................................................................................................
D                         = require 'pipedreams'
{ $, $async, }            = D
#...........................................................................................................
mkdirp                    = require 'mkdirp'
PATCHER                   = require './patch-event-emitter'

###
adapted from
https://strongloop.com/strongblog/practical-examples-of-the-new-node-js-streams-api/
###

stream  = require 'stream'
liner   = new stream.Transform objectMode: true

liner._transform = ( chunk, encoding, done ) ->
  data = chunk.toString()
  if @_lastLineData
    data = @_lastLineData + data
  lines = data.split '\n'
  @_lastLineData = ( lines.splice lines.length - 1, 1 )[ 0 ]
  lines.forEach @push.bind @
  done()
  return

liner._flush = (done) ->
  if @_lastLineData
    @push @_lastLineData
  @_lastLineData = null
  done()
  return


#===========================================================================================================
mkdirp.sync PATH.dirname O.outputs.lines
# settings        = { highWaterMark: 16000, }
settings        = { highWaterMark: 1e6, }
# input           = FS.createReadStream O.inputs.tiny
input           = FS.createReadStream   O.inputs.long,   settings
output          = FS.createWriteStream  O.outputs.lines, settings
PATCHER.patch_timer_etc input, output



input.pipe output
# input.on  'end',    ( ) -> info "input/end"
# input.on  'finish', ( ) -> info "input/finish"
# input.on  'close',  ( ) -> info "input/close"
# output.on 'end',    ( ) -> info "output/end"
# output.on 'finish', ( ) -> info "output/finish"
# output.on 'close',  ( ) -> info "output/close"




