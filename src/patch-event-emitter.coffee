

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'BASIC-STREAM-BENCHMARKS/PATCH-EVENT-EMITTER'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
new_numeral               = require 'numeral'
format_float              = ( x ) -> ( new_numeral x ).format '0,0.000'
format_integer            = ( x ) -> ( new_numeral x ).format '0,0'


#-----------------------------------------------------------------------------------------------------------
@patch_event_emitter = ( name, event_emitter, exclude = null ) ->
  ### TAINT safeguard against applying multiple patches; re-use same method for all event emitters ###
  _emit = event_emitter.emit.bind event_emitter
  #.........................................................................................................
  event_emitter.emit = ( event_name, P... ) =>
    _emit '*',  event_name, P...
    _emit       event_name, P...
    return null
  #.........................................................................................................
  event_emitter.on '*', ( event_name, P... ) =>
    unless exclude? and event_name in exclude
      debug '33201', "#{name}/#{event_name}"
    return null
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
exclude_events  = [
  'pipe'
  'resume'
  # 'open'
  # 'open'
  'data'
  'readable'
  # 'end'
  'prefinish'
  # 'finish'
  'unpipe'
  ]

#-----------------------------------------------------------------------------------------------------------
@patch_timer_etc = ( input, output ) ->
  @patch_event_emitter 'input',  input,  exclude_events
  @patch_event_emitter 'output', output, exclude_events
  t0 = null
  t1 = null
  input.on 'open', -> t0 = Date.now()
  output.on 'close', ->
    t1      = Date.now()
    dts     = ( t1 - t0 ) / 1000
    dts_txt = format_float dts
    help "#{dts_txt}s"
  #.........................................................................................................
  return null










