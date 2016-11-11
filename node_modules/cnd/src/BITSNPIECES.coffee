


############################################################################################################
njs_path                  = require 'path'
njs_fs                    = require 'fs'
njs_util                  = require 'util'
rpr                       = njs_util.inspect
CND                       = require './main'

#-----------------------------------------------------------------------------------------------------------
@equals = ( P... ) -> ( require './jkroso-equals' ) P...

#-----------------------------------------------------------------------------------------------------------
@deep_copy = ( P... ) -> ( require './universal-copy' ) P...

#-----------------------------------------------------------------------------------------------------------
@format_number = ( n, grouper = "'" ) ->
  ### A simple number formatter. ###
  n       = n.toString()
  f       = ( n ) -> return h n, /(\d+)(\d{3})/
  h       = ( n, re ) -> n = n.replace re, "$1" + grouper + "$2" while re.test n; return n
  return f n

#-----------------------------------------------------------------------------------------------------------
@escape_regex = ( text ) ->
  ### Given a `text`, return the same with all regular expression metacharacters properly escaped. Escaped
  characters are `[]{}()*+?-.,\^$|#` plus whitespace. ###
  #.........................................................................................................
  return text.replace /[-[\]{}()*+?.,\\\/^$|#\s]/g, "\\$&"

#-----------------------------------------------------------------------------------------------------------
@escape_html = ( text ) ->
  ### Given a `text`, return the same with all characters critical in HTML (`&`, `<`, `>`) properly
  escaped. ###
  R = text
  R = R.replace /&/g, '&amp;'
  R = R.replace /</g, '&lt;'
  R = R.replace />/g, '&gt;'
  #.........................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
@find_all = ( text, matcher ) ->
  ### `CND.find_all` expects a `text` and a `matcher` (which must be a RegExp object); it returns a
  (possibly empty) list of all matching parts in the text. If `matcher` does not have the `g` (global) flag
  set, a new RegExp object will be cloned behind the scenes, so passsing in a regular expression with `g`
  turned on may improve performance.

  With thanks to http://www.2ality.com/2013/08/regexp-g.html,
  http://www.2ality.com/2011/04/javascript-overview-of-regular.html.
  ###
  unless ( Object::toString.call matcher is '[object RegExp]' ) and matcher.global
    flags   = if matcher.multiline then 'gm' else 'g'
    flags  += 'i' if matcher.ignoreCase
    flags  += 'y' if matcher.sticky
    matcher = ( new RegExp matcher.source, flags )
  throw new Error "matcher must be a RegExp object with global flag set" unless matcher.global
  matcher.lastIndex = 0
  return ( text.match matcher ) ? []

#===========================================================================================================
# UNSORTING
#-----------------------------------------------------------------------------------------------------------
@shuffle = ( list, ratio = 1 ) ->
  ### Shuffles the elements of a list randomly. After the call, the elements of will be—most of the time—
  be reordered (but this is not guaranteed, as there is a realistic probability for recurrence of orderings
  with short lists).

  This is an implementation of the renowned Fisher-Yates algorithm, but with a twist: You may pass in a
  `ratio` as second argument (which should be a float in the range `0 <= ratio <= 1`); if set to a value
  less than one, a random number will be used to decide whether or not to perform a given step in the
  shuffling process, so lists shuffled with zero-ish ratios will show less disorder than lists shuffled with
  a one-ish ratio.

  Implementation gleaned from http://stackoverflow.com/a/962890/256361. ###
  #.........................................................................................................
  return list if ( this_idx = list.length ) < 2
  return @_shuffle list, ratio, Math.random, @random_integer.bind @

#-----------------------------------------------------------------------------------------------------------
@get_shuffle = ( seed_0 = 0, seed_1 = 1 ) ->
  ### This method works similar to `get_rnd`; it accepts two `seed`s which are used to produce random number
  generators and returns a predictable shuffling function that accepts arguments like Bits'N'Pieces
  `shuffle`. ###
  rnd             = @get_rnd      seed_0
  random_integer  = @get_rnd_int  seed_1
  return ( list, ratio = 1 ) => @_shuffle list, ratio, rnd, random_integer

#-----------------------------------------------------------------------------------------------------------
@_shuffle = ( list, ratio, rnd, random_integer ) ->
  #.........................................................................................................
  return list if ( this_idx = list.length ) < 2
  #.........................................................................................................
  loop
    this_idx += -1
    return list if this_idx < 1
    if ratio >= 1 or rnd() <= ratio
      # return list if this_idx < 1
      that_idx = random_integer 0, this_idx
      [ list[ that_idx ], list[ this_idx ] ] = [ list[ this_idx ], list[ that_idx ] ]
  #.........................................................................................................
  return list



#===========================================================================================================
# RANDOM NUMBERS
#-----------------------------------------------------------------------------------------------------------
### see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number ###
@MIN_SAFE_INTEGER = -( 2 ** 53 ) - 1
@MAX_SAFE_INTEGER = +( 2 ** 53 ) - 1

#-----------------------------------------------------------------------------------------------------------
@random_number = ( min = 0, max = 1 ) ->
  ### Return a random number between min (inclusive) and max (exclusive).
  From https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Math/random
  via http://stackoverflow.com/a/1527820/256361. ###
  return Math.random() * ( max - min ) + min

#-----------------------------------------------------------------------------------------------------------
@integer_from_normal_float = ( x, min = 0, max = 2 ) ->
  ### Given a 'normal' float `x` so that `0 <= x < 1`, return an integer `n` so that `min <= n < min`. ###
  return ( Math.floor x * ( max - min ) ) + min

#-----------------------------------------------------------------------------------------------------------
@random_integer = ( min = 0, max = 2 ) ->
  ### Return a random integer between min (inclusive) and max (inclusive).
  From https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Math/random
  via http://stackoverflow.com/a/1527820/256361. ###
  return @integer_from_normal_float Math.random(), min, max

#-----------------------------------------------------------------------------------------------------------
@get_rnd_int = ( seed = 1, delta = 1 ) ->
  ### Like `get_rnd`, but returns a predictable random integer generator. ###
  rnd = @get_rnd seed, delta
  return ( min = 0, max = 1 ) => @integer_from_normal_float rnd(), min, max

#-----------------------------------------------------------------------------------------------------------
@get_rnd = ( seed = 1, delta = 1 ) ->
  ### This method returns a simple deterministic pseudo-random number generator—basically like
  `Math.random`, but (1) very probably with a much worse distribution of results, and (2) with predictable
  series of numbers, which is good for some testing scenarios. You may seed this method by passing in a
  `seed` and a `delta`, both of which must be non-zero numbers; the ensuing series of calls to the returned
  method will then always result in the same series of numbers. Here is a usage example that also shows how
  to reset the generator:

      CND = require 'cnd'
      rnd = CND.get_rnd() # or, say, `rnd = CND.get_rnd 123, 0.5`
      log rnd() for idx in [ 0 .. 5 ]
      log()
      rnd.reset()
      log rnd() for idx in [ 0 .. 5 ]

  Please note that there are no strong guarantees made about the quality of the generated values except the
  (1) deterministic repeatability, (2) boundedness, and (3) 'apparent randomness'. Do **not** use this for
  cryptographic purposes. ###
  #.........................................................................................................
  R = ->
    R._idx  += 1
    x       = ( Math.sin R._s ) * 10000
    R._s    += R._delta
    return x - Math.floor x
  #.........................................................................................................
  R.reset = ( seed, delta ) ->
    ### Reset the generator. After calling `rnd.reset` (or `rnd.seed` with the same arguments), ensuing calls
    to `rnd` will always result in the same sequence of pseudo-random numbers. ###
    seed   ?= @._seed
    delta  ?= @._delta
    #.......................................................................................................
    validate_isa_number seed
    validate_isa_number delta
    #.......................................................................................................
    throw new Error "seed should not be zero"  unless seed  != 0
    throw new Error "delta should not be zero" unless delta != 0
    #.......................................................................................................
    R._s     = seed
    R._seed  = seed
    R._delta = delta
    R._idx   = -1
    return null
  #.........................................................................................................
  R.reset seed, delta
  #.........................................................................................................
  return R


#-----------------------------------------------------------------------------------------------------------
### TAINT code duplication (to avoid dependency on CoffeeNode Types). ###
validate_isa_number = ( x ) ->
  unless ( Object::toString.call x ) == '[object Number]' and isFinite x
    throw "expected a number, got #{( require 'util' ).inspect x}"


#===========================================================================================================
# PODs
#-----------------------------------------------------------------------------------------------------------
@pluck = ( x, name, fallback ) ->
  ### Given some object `x`, a `name` and a `fallback`, return the value of `x[ name ]`, or, if it does not
  exist, `fallback`. When the method returns, `x[ name ]` has been deleted. ###
  if x[ name ]?
    R = x[ name ]
    delete x[ name ]
  else
    R = fallback
  return R


#===========================================================================================================
# ROUTES
#-----------------------------------------------------------------------------------------------------------
@get_parent_routes = ( route ) ->
  R = []
  #.........................................................................................................
  loop
    R.push route
    break if route.length is 0 or route is '/'
    route = njs_path.dirname route
  #.........................................................................................................
  return R


#===========================================================================================================
# CALLER LOCATION
#-----------------------------------------------------------------------------------------------------------
@get_V8_CallSite_objects = ( error = null ) ->
  ### Save original Error.prepareStackTrace ###
  prepareStackTrace_original = Error.prepareStackTrace
  #.........................................................................................................
  Error.prepareStackTrace = ( ignored, stack ) -> return stack
  error                  ?= new Error()
  R                       = error.stack
  #.........................................................................................................
  ### Restore original Error.prepareStackTrace ###
  Error.prepareStackTrace = prepareStackTrace_original
  #.........................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
@get_caller_info_stack = ( delta = 0, error = null, limit = Infinity, include_source = no ) ->
  ### Return a list of PODs representing information about the call stack; newest items will be closer
  to the start ('top') of the list.

  `delta` represents the call distance of the site the inquirer is interested about, relative to the
  *inquirer*; this will be `0` if that is the very line where the call originated from, `1` in case another
  function is called to collect this information, and so on.

  A custom error will be produced and analyzed (with a suitably adjusted value for `delta`) in case no
  `error` has been given. Often, one will want to use this facility to see what the source for a caught
  error looks like; in that case, just pass in the caught `error` object along with a `delta` of (typically)
  `0` (because the error really originated where the problem occurred).

  It is further possible to cut down on the amount of data returned by setting `limit` to a smallish
  number; entries too close (with a stack index smaller than `delta`) or too far from the interesting
  point will be omitted.

  When `include_source` is `true`, an attempt will be made to open each source file, read its contents,
  split it into lines, and include the indicated line in the respective entry. Note that this is currently
  done in a very stupid, blocking, and non-memoizing way, so try not to do that if your stack trace is
  hundreds of lines long and includes megabyte-sized sources.

  Also see `get_caller_info`, which should be handy if you do not need an entire stack but just a single
  targetted entry.

  Have a look at https://github.com/loveencounterflow/guy-test to see how to use the BNP caller info
  methods to copy with error locations in an asynchronous world. ###
  #.........................................................................................................
  delta      += +2 unless error?
  call_sites  = @get_V8_CallSite_objects error
  R           = []
  #.........................................................................................................
  for cs, idx in call_sites
    continue if delta? and idx < delta
    break if R.length >= limit
    entry =
      'function-name':    cs.getFunctionName()
      'method-name':      cs.getMethodName()
      'route':            cs.getFileName()
      'line-nr':          cs.getLineNumber()
      'column-nr':        cs.getColumnNumber()
    entry[ 'source' ] = @_source_line_from_caller_info entry if include_source
    R.push entry
  #.........................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
@get_caller_info = ( delta = 0, error = null, include_source = no ) ->
  R = null
  while delta >= 0 and not R?
    R       = ( @get_caller_info_stack delta, error, 1, include_source )[ 0 ]
    delta  += -1
  # console.log '©3cc0i', rpr R
  return R

#-----------------------------------------------------------------------------------------------------------
@_source_line_from_caller_info = ( info ) ->
  route           = info[ 'route'   ]
  line_nr         = info[ 'line-nr' ]
  try
    source_lines    = ( njs_fs.readFileSync route, encoding: 'utf-8' ).split /\r?\n/
    R               = source_lines[ line_nr - 1 ]
  catch error
    R               = null
  return R


#===========================================================================================================
# ID CREATION
#-----------------------------------------------------------------------------------------------------------
@create_id = ( values, length ) ->
  ### Given a number of `values` and a `length`, return an ID with `length` hexadecimal digits (`[0-9a-f]`)
  that deterministically depends on the input but can probably not reverse-engeneered to yield the input
  values. This is in no way meant to be cryptographically strong, just arbitrary enough so that we have a
  convenient method to derive an ID with little chance of overlap given different inputs. **Note** It is
  certainly possible to use this method (or `id_from_text`) to create a hash from a password to be stored in
  a DB. Don't do this. Use `bcrypt` or similar best-practices for password storage. Again, the intent of
  the BITSNPIECES ID utilities is *not* to be 'crypto-safe'; its intent is to give you a tool for generating
  repetition-free IDs. ###
  return @id_from_text ( ( rpr value for value in values ).join '-' ), length

#-----------------------------------------------------------------------------------------------------------
@create_random_id = ( values, length ) ->
  ### Like `create_id`, but with an extra random factor built in that should exclude that two identical
  outputs are ever returned for any two identical inputs. Under the assumption that two calls to this
  method are highly unlikely two produce an identical pair `( 1 * new Date(), Math.random() )` (which could
  only happen if `Math.random()` returned the same number again *within the same clock millisecond*), and
  assuming you are using a reasonable value for `length` (i.e., say, `7 < length < 20`), you should never
  see the same ID twice. ###
  values.push 1 * new Date() * Math.random()
  return @create_id values, length

#-----------------------------------------------------------------------------------------------------------
@get_create_rnd_id = ( seed, delta ) ->
  ### Given an optional `seed` and `delta`, returns a function that will create pseudo-random IDs similar to
  the ones `create_random_id` returns; however, the Bits'n'Pieces `get_rnd` method is used to obtain a
  repeatable random number generator so that ID sequences are repeatable. The underlying PRNG is exposed as
  `fn.rnd`, so `fn.rnd.reset` may be used to start over.

  **Use Case Example**: The below code demonstrates the interesting properties of the method returned by
  `get_create_rnd_id`: **(1)** we can seed the PRNG with numbers of our choice, so we get a chance to create
  IDs that are unlikely to be repeated by other people using the same software, even when later inputs (such
  as the email adresses shown here) happen to be the same. **(2)** Calling the ID generator with three
  diffferent user-specific inputs, we get three different IDs, as expected. **(3)** Repeating the ID
  generation calls with the *same* arguments will yield *different* IDs. **(4)** After calling
  `create_rnd_id.rnd.reset()` and feeding `create_rnd_id` with the *same* user-specific inputs, we can still
  see the identical *same* IDs generated—which is great for testing.

      create_rnd_id = CND.get_create_rnd_id 1234, 87.23

      # three different user IDs:
      log create_rnd_id [ 'foo@example.com' ], 12
      log create_rnd_id [ 'alice@nosuchname.com' ], 12
      log create_rnd_id [ 'tim@cern.ch' ], 12

      # the same repeated, but yielding random other IDs:
      log()
      log create_rnd_id [ 'foo@example.com' ], 12
      log create_rnd_id [ 'alice@nosuchname.com' ], 12
      log create_rnd_id [ 'tim@cern.ch' ], 12

      # the same repeated, but yielding the same IDs as in the first run:
      log()
      create_rnd_id.rnd.reset()
      log create_rnd_id [ 'foo@example.com' ], 12
      log create_rnd_id [ 'alice@nosuchname.com' ], 12
      log create_rnd_id [ 'tim@cern.ch' ], 12

  The output you should see is

      c40f774fce65
      9d44f31f9a55
      1b26e6e3e736

      a0e11f616685
      d7242f6935c7
      976f26d1b25b

      c40f774fce65
      9d44f31f9a55
      1b26e6e3e736

  Note the last three IDs exactly match the first three IDs. The upshot of this is that we get reasonably
  hard-to-guess, yet on-demand replayable IDs. Apart from weaknesses in the PRNG itself (for which see the
  caveats in the description to `get_rnd`), the obvious way to cheat the system is by making it so that
  a given piece of case-specific data is fed into the ID generator as the n-th call a second time. In
  theory, we could make it so that each call constributes to the state change inside of `create_rnd_id`;
  a replay would then need to provide all of the case-specific pieces of data a second time, in the right
  order. ###
  #.........................................................................................................
  R = ( values, length ) =>
    values.push R.rnd()
    return @create_id values, length
  #.........................................................................................................
  R.rnd = @get_rnd seed, delta
  #.........................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
@id_from_text = ( text, length ) ->
  ### Given a `text` and a `length`, return an ID with `length` hexadecimal digits (`[0-9a-f]`)—this is like
  `create_id`, but working on a text rather than a number of arbitrary values. The hash algorithm currently
  used is SHA-1, which returns 40 hex digits; it should be good enough for the task at hand and has the
  advantage of being widely implemented. ###
  ### TAINT should be a user option, or take 'good' algorithm universally available ###
  R = ( ( ( require 'crypto' ).createHash 'sha1' ).update text, 'utf-8' ).digest 'hex'
  return if length? then R[ 0 ... length ] else R

#-----------------------------------------------------------------------------------------------------------
@id_from_route = ( route, length, handler ) ->
  ### Like `id_from_text`, but accepting a file route instead of a text. ###
  throw new Error "asynchronous `id_from_route` not yet supported" if handler?
  content = njs_fs.readFileSync route
  R       = ( ( ( require 'crypto' ).createHash 'sha1' ).update content ).digest 'hex'
  return if length? then R[ 0 ... length ] else R


#===========================================================================================================
# APP INFO
#-----------------------------------------------------------------------------------------------------------
@get_app_home = ( routes = null ) ->
  ### Return the file system route to the current (likely) application folder. This works by traversing all
  the routes in `require[ 'main' ][ 'paths' ]` and checking whether one of the `node_modules` folders
  listed there exists and is a folder; the first match is accepted and returned. If no matching existing
  route is found, an error is thrown.

  NB that the algorithm works even if the CoffeeNode Options module has been symlinked from another location
  (rather than 'physically' installed) and even if the application main file has been executed from outside
  the application folder (i.e. this obviates the need to `cd ~/route/to/my/app` before doing `node ./start`
  or whatever—you can simply do `node ~/route/to/my/app/start`), but it does presuppose that (1) there *is*
  a `node_modules` folder in your app folder; (2) there is *no* `node_modules` folder in the subfolder or
  any of the intervening levels (if any) that contains your startup file. Most modules that follow the
  established NodeJS / npm way of structuring modules should naturally comply with these assumptions. ###
  njs_fs = require 'fs'
  routes ?= require[ 'main' ][ 'paths' ]
  #.........................................................................................................
  for route in routes
    try
      return njs_path.dirname route if ( njs_fs.statSync route ).isDirectory()
    #.......................................................................................................
    catch error
      ### silently ignore missing routes: ###
      continue if error[ 'code' ] is 'ENOENT'
      throw error
  #.........................................................................................................
  throw new Error "unable to determine application home; tested routes: \n\n #{routes.join '\n '}\n"

#===========================================================================================================
# FS ROUTES
#-----------------------------------------------------------------------------------------------------------
@swap_extension = ( route, extension ) ->
  extension = '.' + extension unless extension[ 0 ] is '.'
  extname   = njs_path.extname route
  return route[ 0 ... route.length - extname.length ] + extension

#===========================================================================================================
# LISTS
#-----------------------------------------------------------------------------------------------------------
@first_of   = ( collection ) -> collection[ 0 ]
@last_of    = ( collection ) -> collection[ collection.length - 1 ]



#===========================================================================================================
# OBJECT SIZES
#-----------------------------------------------------------------------------------------------------------
@size_of = ( x, settings ) ->
  switch type = CND.type_of x
    when 'list', 'arguments', 'buffer' then return x.length
    when 'text'
      switch selector = settings?[ 'count' ] ? 'codeunits'
        when 'codepoints' then return ( Array.from x ).length
        when 'codeunits'  then return x.length
        when 'bytes'      then return Buffer.byteLength x, ( settings?[ 'encoding' ] ? 'utf-8' )
        else throw new Error "unknown counting selector #{rpr selector}"
    when 'set', 'map'     then return x.size
  if CND.isa_pod x then return ( Object.keys x ).length
  throw new Error "unable to get size of a #{type}"



#===========================================================================================================
# NETWORK
#-----------------------------------------------------------------------------------------------------------
@get_local_ips = ->
  ### thx to http://stackoverflow.com/a/10756441/256361 ###
  R = []
  for _, interface_ of ( require 'os' ).networkInterfaces()
    for description in interface_
      if description[ 'family' ] is 'IPv4' and not description[ 'internal' ]
        R.push description[ 'address' ]
  return R

#===========================================================================================================
# SETS
#-----------------------------------------------------------------------------------------------------------
@is_subset = ( subset, superset ) ->
  ### `is_subset subset, superset` returns whether `subset` is a subset of `superset`; this is true if each
  element of `subset` is also an element of `superset`. ###
  type_of_sub   = CND.type_of subset
  type_of_super = CND.type_of superset
  unless type_of_sub is type_of_super
    throw new Error "expected two arguments of same type, got #{type_of_sub} and #{type_of_super}"
  switch type_of_sub
    when 'list'
      return false unless subset.length <= superset.length
      for element in subset
        return false unless element in superset
      return true
    when 'set'
      return false unless subset.size <= superset.size
      iterator = subset.values()
      loop
        { value, done, } = iterator.next()
        return true if done
        return false unless superset.has value
      # for element in
      #   return false unless element in subset
      return true
    else
      throw new Error "expected lists or sets, got #{type_of_sub} and #{type_of_super}"
  return null


#===========================================================================================================
# ERROR HANDLING
#-----------------------------------------------------------------------------------------------------------
@run = ( method, on_error = null, on_after_error = null ) ->
  ### Provide asynchronous error handling and long stacktraces. Usage:

  To run a method, catch all the synchronous and asynchronous errors and print a stacktrace
  to `process.stderr` (using `console.error`):

  ```coffee
  CND.run -> f 42
  ```

  Same as the above, but do the error handling yourself:

  ```coffee
  CND.run ( -> f 42 ), ( error ) -> foobar()
  ```

  Same as the last, except have CND output the error's stacktrace and be called back afterwards:

  ```coffee
  CND.run ( -> f 42 ), null, ( error ) -> foobar()
  ```

  NB.: `CND.run` may be made configurable in the future; as of now, it is hardwired to use colors
  and always provide long (cross-event) stack traces. Colors used are blue for NodeJS VM built-ins,
  green for errors originating from modules installed under `node_modules`, and yellow for everything
  else.

  ###
  on_error         ?= ( error ) ->
    console.error error[ 'stack' ]
    on_after_error error if on_after_error?
  trycatch          = require 'trycatch'
  #.........................................................................................................
  trycatch_settings =
    'long-stack-traces': yes
    'colors':
      # 'none' or falsy values will omit
      'node':         'blue',
      'node_modules': 'green',
      'default':      'yellow'
  #.........................................................................................................
  trycatch.configure trycatch_settings
  trycatch method, on_error
  #.........................................................................................................
  return null
