

############################################################################################################
CND                       = require './main'
rpr                       = CND.rpr
log                       = console.log
# badge                     = 'scratch'
# log                       = CND.get_logger 'plain',     badge
# info                      = CND.get_logger 'info',      badge
# whisper                   = CND.get_logger 'whisper',   badge
# alert                     = CND.get_logger 'alert',     badge
# debug                     = CND.get_logger 'debug',     badge
# warn                      = CND.get_logger 'warn',      badge
# help                      = CND.get_logger 'help',      badge
# urge                      = CND.get_logger 'urge',      badge
# echo                      = CND.echo.bind CND
# rainbow                   = CND.rainbow.bind CND
# suspend                   = require 'coffeenode-suspend'
# step                      = suspend.step
# after                     = suspend.after
# eventually                = suspend.eventually
# immediately               = suspend.immediately
# every                     = suspend.every

#-----------------------------------------------------------------------------------------------------------
@replacer = ( key, value ) ->
  ### NOTE Buffers are treated specially; at this point, they are already converted into sth that looks
  like `{ type: 'Buffer', data: [ ... ], }`. ###
  if ( CND.isa_pod value ) and ( value[ 'type' ] is 'Buffer' ) and ( CND.isa_list data = value[ 'data' ] )
    return { '~isa': '-x-buffer',    '%self': data, }
  #.........................................................................................................
  switch type = CND.type_of value
    #.......................................................................................................
    when 'nan'          then  return { '~isa': '-x-nan',        }
    #.......................................................................................................
    when 'set'          then  return { '~isa': '-x-set',       '%self': ( Array.from value ), }
    when 'map'          then  return { '~isa': '-x-map',       '%self': ( Array.from value ), }
    when 'function'     then  return { '~isa': '-x-function',  '%self': ( value.toString() ), }
    #.......................................................................................................
    when 'symbol'
      data    = value.toString().replace /^Symbol\((.*)\)$/, '$1'
      local   = value is Symbol.for data
      return { '~isa': '-x-symbol', local, '%self': data, }
  #.........................................................................................................
  return value

#-----------------------------------------------------------------------------------------------------------
@reviver = ( key, value ) ->
  #.........................................................................................................
  switch type = CND.type_of value
    #.......................................................................................................
    when '-x-nan'       then  return NaN
    #.......................................................................................................
    when '-x-buffer'    then  return Buffer.from value[ '%self' ]
    when '-x-set'       then  return new Set value[ '%self' ]
    when '-x-map'       then  return new Map value[ '%self' ]
    when '-x-function'  then  return ( eval "[ " + value[ '%self' ] + " ]" )[ 0 ]
    when '-x-symbol'    then  return Symbol.for value[ '%self' ]
  #.........................................................................................................
  return value

#-----------------------------------------------------------------------------------------------------------
@stringify = ( value, replacer, spaces ) ->
  replacer ?= @replacer
  return JSON.stringify value, replacer, spaces

#-----------------------------------------------------------------------------------------------------------
@parse = ( text, reviver ) ->
  reviver ?= @reviver
  return JSON.parse text, reviver

#-----------------------------------------------------------------------------------------------------------
@replacer   = @replacer.bind  @
@reviver    = @reviver.bind   @
@stringify  = @stringify.bind @
@parse      = @parse.bind     @

