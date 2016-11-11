


### LIST methods ###


#.......................................................................................................
insert = ( list, item, idx = 0 ) ->
  list.splice idx, 0, item
  return list
#.......................................................................................................
rotate_left = ( list, count = 1 ) ->
  return list if list.length is 0
  list.push list.shift() for _ in [ 0 ... count ]
  return list
#.......................................................................................................
rotate_right = ( list, count = 1 ) ->
  return list if list.length is 0
  list.unshift list.pop() for _ in [ 0 ... count ]
  return list
