



############################################################################################################
@constants                = require './TRM-CONSTANTS'
@separator                = ' '
@depth_of_inspect         = 20
badge                     = 'TRM'
TYPES                     = require './TYPES'
isa_text                  = TYPES.isa_text.bind TYPES
_rpr                      = ( require 'util' ).inspect
@ANSI                     = require './TRM-VT100-ANALYZER'


# #-----------------------------------------------------------------------------------------------------------
# @rpr = ( x ) ->
#   try
#     if x.toString? and ( x.toString isnt Object::toString )
#       return x.toString()
#     else
#       return @_rpr x
#   catch error
#     throw error unless /^Cannot read property/.test error[ 'message' ]
#     return @_rpr x

#-----------------------------------------------------------------------------------------------------------
@rpr = ( x ) ->
  return _rpr x, depth: @depth_of_inspect

#-----------------------------------------------------------------------------------------------------------
@get_output_method = ( target, options ) ->
  return ( P... ) => target.write @pen P...

#-----------------------------------------------------------------------------------------------------------
@pen = ( P... ) ->
  ### Given any number of arguments, return a text representing the arguments as seen fit for output
  commands like `log`, `echo`, and the colors. ###
  return ( @_pen P... ).concat '\n'

#-----------------------------------------------------------------------------------------------------------
@_pen = ( P... ) ->
  ### ... ###
  R = ( ( if isa_text p then p else @rpr p ) for p in P )
  return R.join @separator

#-----------------------------------------------------------------------------------------------------------
@log                      = @get_output_method process.stderr
@echo                     = @get_output_method process.stdout

#===========================================================================================================
# KEY CAPTURING
#-----------------------------------------------------------------------------------------------------------
@listen_to_keys = ( handler ) ->
  ### thx to http://stackoverflow.com/a/12506613/256361 ###
  #.........................................................................................................
  ### try not to bind handler to same handler more than once: ###
  return null if handler.__TRM__listen_to_keys__is_registered
  Object.defineProperty handler, '__TRM__listen_to_keys__is_registered', value: true, enumerable: false
  help                = @get_logger 'help', badge
  last_key_was_ctrl_c = false
  R                   = process.openStdin()
  R.setRawMode  true
  R.setEncoding 'utf-8'
  R.resume()
  #.........................................................................................................
  R.on 'data', ( key ) =>
    response = handler key
    if key is '\u0003'
      process.exit() if last_key_was_ctrl_c
      last_key_was_ctrl_c = yes
      help "press ctrl-C again to exit"
    else
      last_key_was_ctrl_c = no
  #.........................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
@ask = ( prompt, handler ) ->
  rl = ( require 'readline' ).createInterface
    input:  process.stdin
    output: process.stdout
  #.........................................................................................................
  prompt += ' ' unless /\s+$/.test prompt
  rl.question ( @cyan prompt ), ( answer ) ->
    rl.close()
    handler null, answer


# #===========================================================================================================
# # SHELL COMMANDS
# #-----------------------------------------------------------------------------------------------------------
# @execute = ( command, handler ) ->
#   unless handler?
#     ### https://github.com/gvarsanyi/sync-exec ###
#     exec = require 'sync-exec'
#     #...........................................................................................................
#     { stdout
#       stderr
#       status } = exec 'ls'
#     throw new Error stderr if stderr? and stderr.length > 0
#     return lines_from_stdout stdout
#   #.........................................................................................................
#   ( require 'child_process' ).exec O[ 'on-change' ], ( error, stdout, stderr ) =>
#     return handler error if error?
#     return handler new Error stderr if stderr? and stderr.length isnt 0
#     handler null, lines_from_stdout stdout
#   #.........................................................................................................
#   return null

#-----------------------------------------------------------------------------------------------------------
lines_from_stdout = ( stdout ) ->
  R = stdout.split '\n'
  R.length -= 1 if R[ R.length - 1 ].length is 0
  return R

#-----------------------------------------------------------------------------------------------------------
@spawn = ( command, parameters, handler ) ->
  R = ( require 'child_process' ).spawn command, parameters, { stdio: 'inherit', }
  R.on 'close', handler
  #.........................................................................................................
  return R


#===========================================================================================================
# COLORS & EFFECTS
#-----------------------------------------------------------------------------------------------------------
@clear_line_right         = @constants.clear_line_right
@clear_line_left          = @constants.clear_line_left
@clear_line               = @constants.clear_line
@clear_below              = @constants.clear_below
@clear_above              = @constants.clear_above
@clear                    = @constants.clear

#-----------------------------------------------------------------------------------------------------------
@goto                     = ( line_nr = 1, column_nr = 1 )  -> return "\x1b[#{line_nr};#{column_nr}H"
@goto_column              = ( column_nr = 1 )  -> return "\x1b[#{column_nr}G"
#...........................................................................................................
@up                       = ( count = 1 ) -> return "\x1b[#{count}A"
@down                     = ( count = 1 ) -> return "\x1b[#{count}B"
@right                    = ( count = 1 ) -> return "\x1b[#{count}C"
@left                     = ( count = 1 ) -> return "\x1b[#{count}D"
#...........................................................................................................
@move = ( line_count, column_count ) ->
  return ( ( if   line_count < 0 then @up     line_count else @down    line_count ) +
           ( if column_count < 0 then @left column_count else @right column_count ) )

#-----------------------------------------------------------------------------------------------------------
@ring_bell = ->
  process.stdout.write "\x07"

#-----------------------------------------------------------------------------------------------------------
effect_names =
  blink:        1
  bold:         1
  reverse:      1
  underline:    1
#...........................................................................................................
for effect_name of effect_names
  effect_on       = @constants[         effect_name ]
  effect_off      = @constants[ 'no_' + effect_name ]
  do ( effect_name, effect_on, effect_off ) =>
    @[ effect_name ] = ( P... ) =>
      R         = [ effect_on, ]
      last_idx  = P.length - 1
      for p, idx in P
        R.push if isa_text p then p else @rpr p
        if idx isnt last_idx
          R.push effect_on
          R.push @separator
      R.push effect_off
      return R.join ''
#...........................................................................................................
for color_name, color_code of @constants[ 'colors' ]
  do ( color_name, color_code ) =>
    @[ color_name ] = ( P... ) =>
      R         = [ color_code, ]
      last_idx  = P.length - 1
      for p, idx in P
        R.push if isa_text p then p else @rpr p
        if idx isnt last_idx
          R.push color_code
          R.push @separator
      R.push @constants[ 'reset' ]
      return R.join ''

#-----------------------------------------------------------------------------------------------------------
@remove_colors = ( text ) ->
  # this one from http://regexlib.com/UserPatterns.aspx?authorId=f3ce5c3c-5970-48ed-9c4e-81583022a387
  # looks smarter but isn't JS-compatible:
  # return text.replace /(?s)(?:\e\[(?:(\d+);?)*([A-Za-z])(.*?))(?=\e\[|\z)/g, ''
  return text.replace @color_matcher, ''

#-----------------------------------------------------------------------------------------------------------
@color_matcher = /\x1b\[[^m]*m/g

# #-----------------------------------------------------------------------------------------------------------
# $.length_of_ansi_text = ( text ) ->
#   return ( text.replace /\x1b[^m]m/, '' ).length

# #-----------------------------------------------------------------------------------------------------------
# $.truth = ( P... ) ->
#   return ( ( ( if p == true then green else if p == false then red else white ) p ) for p in P ).join ''

#-----------------------------------------------------------------------------------------------------------
# rainbow_color_names = """blue tan cyan sepia indigo steel brown red olive lime crimson green plum orange pink
#                         gold yellow""".split /\s+/
rainbow_color_names = """red orange yellow green blue pink""".split /\s+/
rainbow_idx         = -1

#-----------------------------------------------------------------------------------------------------------
@rainbow = ( P... ) ->
  rainbow_idx = ( rainbow_idx + 1 ) % rainbow_color_names.length
  return @[ rainbow_color_names[ rainbow_idx ] ] P...

#-----------------------------------------------------------------------------------------------------------
@route = ( P... ) ->
  return @lime @underline P...

#-----------------------------------------------------------------------------------------------------------
@truth = ( P... ) ->
  return ( ( if p then @green "✔  #{@_pen p}" else @red "✗  #{@_pen p}" ) for p in P ).join ''

#-----------------------------------------------------------------------------------------------------------
@get_logger = ( category, badge = null ) ->
  #.........................................................................................................
  switch category
    #.......................................................................................................
    when 'plain'
      colorize  = null
      pointer   = @grey ' ▶ '
    #.......................................................................................................
    when 'info'
      colorize  = @BLUE.bind @
      pointer   = @grey ' ▶ '
    #.......................................................................................................
    when 'whisper'
      colorize  = @grey.bind @
      pointer   = @grey ' ▶ '
    #.......................................................................................................
    when 'urge'
      colorize  = @orange.bind @
      pointer   = @bold @RED ' ? '
    #.......................................................................................................
    when 'praise'
      colorize  = @GREEN.bind @
      pointer   = @GREEN ' ✔ '
    #.......................................................................................................
    when 'debug'
      colorize  = @pink.bind @
      pointer   = @grey ' ⚙ '
    #.......................................................................................................
    when 'alert'
      colorize  = @RED.bind @
      pointer   = @blink @RED ' ⚠ '
    #.......................................................................................................
    when 'warn'
      colorize  = @RED.bind @
      pointer   = @bold @RED ' ! '
    #.......................................................................................................
    when 'help'
      colorize  = @lime.bind @
      pointer   = @gold ' ☛ '
    #.......................................................................................................
    else
      throw new Error "unknown logger category #{_rpr category}"
  #.........................................................................................................
  prefix = if badge? then ( @grey badge ).concat ' ', pointer else pointer
  #.........................................................................................................
  if colorize?
    R = ( P... ) => return @log prefix, colorize P...
  else
    R = ( P... ) => return @log prefix, P...
  #.........................................................................................................
  return R


#===========================================================================================================
# EXTRACTING COLORS / CONVERTING COLORS TO HTML
#-----------------------------------------------------------------------------------------------------------
### TAINT naming unstable, to be renamed ###
# @as_html = @ANSI.as_html.bind @ANSI
# @get_css_source = @ANSI.get_css_source.bind @ANSI
# @analyze = @ANSI.analyze.bind @ANSI

#-----------------------------------------------------------------------------------------------------------
@clean = ( text ) ->
  is_ansicode = yes
  R           = []
  #.........................................................................................................
  return ( chunk for chunk in @analyze text when ( is_ansicode = not is_ansicode ) ).join ''


#===========================================================================================================
# VALUE REPORTING
#-----------------------------------------------------------------------------------------------------------
@_prototype_of_object = Object.getPrototypeOf new Object()

#-----------------------------------------------------------------------------------------------------------
@_dir_options =
  'skip-list-idxs':   yes
  'skip-object':      yes

#-----------------------------------------------------------------------------------------------------------
@_marker_by_type =
  'function':       '()'

#-----------------------------------------------------------------------------------------------------------
@dir = ( P... ) ->
  switch arity = P.length
    when 0
      throw new Error "called TRM.dir without arguments"
    when 1
      x = P[ 0 ]
    else
      x = P[ P.length - 1 ]
      @log @rainbow p for p, idx in P when idx < P.length - 1
  width = if process.stdout.isTTY then process.stdout.columns else 108
  r     = ( @rpr x ).replace /\n\s*/g, ' '
  r     = r[ .. Math.max 5, width - 5 ].concat @grey ' ...' if r.length > width
  @log '\n'.concat ( @lime r ), '\n', ( ( @_dir x ).join @grey ' ' ), '\n'

#-----------------------------------------------------------------------------------------------------------
@_dir = ( x ) ->
  R = []
  for [ role, p, type, names, ] in @_get_prototypes_types_and_property_names x, []
    R.push @grey '('.concat role, ')'
    R.push @orange type
    for name in names
      marker = @_marker_from_type TYPES.type_of ( Object.getOwnPropertyDescriptor p, name )[ 'value' ]
      R.push ( @cyan name ).concat @grey marker
  return R

#-----------------------------------------------------------------------------------------------------------
 @_is_list_idx = ( idx_txt, length ) ->
  return false unless /^[0-9]+$/.test idx_txt
  return 0 <= ( parseInt idx_txt ) < length

#-----------------------------------------------------------------------------------------------------------
@_marker_from_type = ( type ) ->
  return @_marker_by_type[ type ] ? '|'.concat type

#-----------------------------------------------------------------------------------------------------------
@_get_prototypes_types_and_property_names = ( x, types_and_names ) ->
  role = if types_and_names.length is 0 then 'type' else 'prototype'
  unless x?
    types_and_names.push [ role, x, ( TYPES.type_of x ), [], ]
    return types_and_names
  #.........................................................................................................
  try
    names           = Object.getOwnPropertyNames x
    prototype       = Object.getPrototypeOf x
  catch error
    throw error unless error[ 'message' ] is 'Object.getOwnPropertyNames called on non-object'
    x_              = new Object x
    names           = Object.getOwnPropertyNames x_
    prototype       = Object.getPrototypeOf x_
  #.........................................................................................................
  try
    length = x.length
    if length?
      names = ( name for name in names when not  @_is_list_idx name, x.length )
  catch error
    throw error unless error[ 'message' ].test /^Cannot read property 'length' of /
  #.........................................................................................................
  names.sort()
  types_and_names.push [ role, x, ( TYPES.type_of x ), names ]
  #.........................................................................................................
  if prototype? and not ( @_dir_options[ 'skip-object' ] and prototype is @_prototype_of_object )
    @_get_prototypes_types_and_property_names prototype, types_and_names
  #.........................................................................................................
  return types_and_names






