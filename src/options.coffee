






############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'BASIC-STREAM-BENCHMARKS/COPY-LINES'
debug                     = CND.get_logger 'debug',     badge



module.exports            = O = {}
O.inputs                  = {}
O.outputs                 = {}
O.inputs.long             = PATH.resolve __dirname, '../test-data/Unicode-NamesList.txt'
O.inputs.short            = PATH.resolve __dirname, '../test-data/Unicode-NamesList-short.txt'
O.inputs.tiny             = PATH.resolve __dirname, '../test-data/Unicode-NamesList-tiny.txt'
O.outputs.lines           = PATH.resolve __dirname, '/tmp/basic-stream-benchmarks/lines.txt'
#...........................................................................................................
