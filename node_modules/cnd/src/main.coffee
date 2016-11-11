

############################################################################################################
njs_util                  = require 'util'
rpr                       = njs_util.inspect

#===========================================================================================================
# ACQUISITION
#-----------------------------------------------------------------------------------------------------------
method_count  = 0
routes        = [ './TRM', './BITSNPIECES', './TYPES', ]
#...........................................................................................................
for route in routes
  for name, value of module = require route
    throw new Error "duplicate name #{rpr name}" if @[ name ]?
    method_count += +1
    value         = value.bind module if ( Object::toString.call value ) is '[object Function]'
    @[ name ]     = value
#...........................................................................................................
@XJSON = require './XJSON'


# ############################################################################################################
# unless module.parent?
#   console.log "acquired #{method_count} names from #{routes.length} sub-modules"
#   @dir @

