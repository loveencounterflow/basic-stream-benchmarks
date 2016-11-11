<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [cnd](#cnd)
  - [CND Interval Tree](#cnd-interval-tree)
  - [CND Shim](#cnd-shim)
  - [CND TSort](#cnd-tsort)
    - [TSort API](#tsort-api)
    - [Some TDOP Links](#some-tdop-links)
  - [XJSON](#xjson)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


# cnd

a grab-bag NodeJS package mainly for functionalities that used to live in
coffeenode-trm, coffeenode-bitsnpieces, and coffeenode-types

## CND Interval Tree

* https://www.youtube.com/watch?v=q0QOYtSsTg4
* https://www.youtube.com/watch?v=PHlTuCVxJz4
* https://github.com/mikolalysenko/functional-red-black-tree


* Simplified API (compared to `functional-red-black-tree`)
* possible to dynamically add nodes
* possible to access underlying red/black tree as `tree[ '%self' ]`, root node as `tree[ '%self' ][ 'root' ]`
* possible to access

```coffee
CND       = require 'cnd'
ITREE     = CND.INTERVALTREE
tree      = ITREE.new_tree()
intervals = [
  [ 3, 7, 'A', ]
  [ 5, 7, 'B', ]
  [ 8, 12, 'C', ]
  [ 2, 14, 'D', ]
  [ 4, 4, 'E', ]
  ]
ITREE.add_interval tree, interval for interval in intervals
for n in [ 0 .. 15 ]
  console.log n
  for node in ITREE.find tree, n
    console.log node[ 'key' ], node[ 'value' ]
```

## CND Shim

CND now includes https://github.com/es-shims/es6-shim and https://github.com/es-shims/es7-shim;
in order to use these, say

```coffee
CND = require 'cnd'
CND.shim()
```

which will then polyfill you current runtime to the point where you approximately
reach compatibility with NodeJS v0.12 run with the `--harmony` switch. Note
that not everything can be polyfilled; in particular WeakMaps and `yield` cannot
be provided this way.

## CND TSort

CND TSort implements a simple tool to perform the often-needed requirement of
doing a [topological sorting](http://en.wikipedia.org/wiki/Topological_sorting)
over an [DAG](http://en.wikipedia.org/wiki/Directed_acyclic_graph) (directed acyclic graph).
It is an adaption of the [npm: tsort](https://github.com/eknkc/tsort) module.

Here is the basic usage: you instantiate a graph by saying e.g.

```coffee
CND       = require 'cnd'
TS        = CND.TSORT
settings  =
  strict:   yes
  prefixes: [ 'f|', 'g|', ]
graph     = TS.new_graph settings
```

The `settings` object itself and its members are optional. The `strict` setting
(true by default) will check for the well-formedness on the graph each time a
relationship is entered; this means you get early errors at the cost of
decreased performance. We come back to the `prefixes` later; the default is not
to use prefixes.

Topological sorting is all about finding a total, linear ordering of actions,
values, objects or whatever from a series of statements about the relative
ordering of pairs of such objects. This is used in many fields, for example in
package management, project management, programming language grammars and so on.

So let's say you have a todo list:

```coffee
'buy books'
'buy food'
'buy food'
'cook'
'do some reading'
'eat'
'fetch money'
'go home'
'go to bank'
'go to exam'
'go to market'
```

Now you don't have money, foods or books at home right now, but you want to eat,
do some reading, and go to the exam after that, so clearly there are certain
orderings of events that would make more sense than other orderings. It's
perhaps not immediately clear how you can organize all these jobs when you look
at the entire list, but given any two jobs, it's often easy to see which one
should preced the other one.

Once we have instantiated a graph `g`, we can add dual relationships piecemeal,
the convention being that we imagine arrows or links pointing from preconditions
'down' to consequences, which is why the corresponding method is named
`link_down`. Calling `TS.link_down g, 'buy food', 'cook'` means: 'Add a link to
graph `g` to indicate that before I can `'cook'`, I have to `'buy food'` first',
and so on. It is customary to symbolically write `'buy food' > 'cook'` to
indicate the dependency.

In case the graph has been instantiated with a `strict: yes` setting, CND TSort
will validate the graph for each single new relationship; as a side effect, a
list of entries is produced and returned that reflects one of the possible
linearizations of the graph which satisfies all requirements so far. For the
purpose of demonstration, we can take advantage of that list and print it out;
we can see that the ordering of jobs will sometimes take a dramatic turn when
new requirements are added. In case you've started the graph with `strict: no`,
you'll have to call `TS.sort g` yourself to perform a validation and obtain
a serialization.—Let's try that for some obvious dependencies on our list:

```coffee
console.log ( TS.link_down g, 'buy food',          'cook'                ).join ' > '
console.log ( TS.link_down g, 'fetch money',       'buy food'            ).join ' > '
console.log ( TS.link_down g, 'do some reading',   'go to exam'          ).join ' > '
console.log ( TS.link_down g, 'cook',              'eat'                 ).join ' > '
console.log ( TS.link_down g, 'go to bank',        'fetch money'         ).join ' > '
console.log ( TS.link_down g, 'fetch money',       'buy books'           ).join ' > '
console.log ( TS.link_down g, 'buy books',         'do some reading'     ).join ' > '
console.log ( TS.link_down g, 'go to market',      'buy food'            ).join ' > '
```
The output from the above will be (re-arranged for readability):

```coffee
                                          buy food > cook
             fetch money >                buy food > cook
             fetch money >                buy food > cook >             do some reading > go to exam
             fetch money >                buy food > cook >             do some reading > go to exam > eat
go to bank > fetch money >                buy food > cook >             do some reading > go to exam > eat
go to bank > fetch money >                buy food > cook >             do some reading > go to exam > eat > buy books
go to bank > fetch money >                buy food > cook > buy books > do some reading > go to exam > eat
go to bank > fetch money > go to market > buy food > cook > buy books > do some reading > go to exam > eat
```
Observe how the requirement `'fetch money' > 'buy books'` made `'buy books'`
appear at the very end of the list, and how only the additonal requirement `'buy
books' > 'do some reading'` managed to put the horse before the cart, as it
were. It still looks as though we're not quite done here yet, as we have to
leave house after cooking and go to the exam with an empty stomach according to
the current linearization, so some dependencies are still missing:

```coffee
console.log ( TS.link_down g, 'buy food',          'go home'             ).join ' > '
console.log ( TS.link_down g, 'buy books',         'go home'             ).join ' > '
console.log ( TS.link_down g, 'go home',           'cook'                ).join ' > '
console.log ( TS.link_down g, 'eat',               'go to exam'          ).join ' > '
```

This makes the order of events more reasonable with each step:

```coffee
go to bank > fetch money > go to market > buy food > cook > buy books > do some reading > go to exam > eat > go home
go to bank > fetch money > go to market > buy food > cook > buy books > do some reading > go to exam > eat > go home
go to bank > fetch money > go to market > buy food > buy books > go home > cook > do some reading > go to exam > eat
go to bank > fetch money > go to market > buy food > buy books > go home > cook > do some reading > eat > go to exam
```
The takeaway up to this point is that although you may have already entered all
relevant activities, it may or or may not be the case that the relationships
define a unique ordering—TSort will always give you *some* ordering, but not
necessarily the only one. TSort remains silent about that. For this reason and
because the precise ordering is dependent upon order of insertion, it may happen
that a given result looks satisfying not because the constraints entered were
both sufficient and complete, but because they happened to be added to the graph
in a fitting sequence. In the same vein, adding more constraints may or may not
change the linearization.

Furthermore, each new requirement may introduce an incompatible constraint. It
is by no means unreasonable as such to require that we want to eat before going
to the bank, but should we call `TS.link_down g, 'eat', 'go to bank'` at this
point in time, TSort will throw an error (immediately if set to `strict`,
otherwise as soon as `TS.sort` is called), complaining that it has `detected
cycle involving node 'buy food'`. Had we added `TS.link_down g, 'eat', 'go to
bank'` first, the error would have resulted upon adding the constraint
`TS.link_down g, 'go to bank', 'fetch money'`; in this case the message would've
been `detected cycle involving node 'eat'`.

Now for a more CS-ish application of TSort; specifically, we want to implement
the ['function table'](https://youtu.be/n5UWAaw_byw?list=PLEbnTDJUr_IcPtUXFy2b1sGRPsLFMghhS&t=1237)
that [Ravindrababu Ravula](https://www.youtube.com/channel/UCJjC1hn78yZqTf0vdTC6wAQ)
derives in his lecture on
[Compiler Design Lecture 9—Operator grammar and Operator precedence parser](https://www.youtube.com/watch?v=n5UWAaw_byw&index=9&list=PLEbnTDJUr_IcPtUXFy2b1sGRPsLFMghhS)
(one of the few materials about Pratt-style Top-Down Operator Parsing (TDOP) i was able to find on the web).

[Operator Precedence Table](https://youtu.be/n5UWAaw_byw?list=PLEbnTDJUr_IcPtUXFy2b1sGRPsLFMghhS&t=488)

| .    | `id`  | `+`   | `*`   | `$`   |
| :--: | :---: | :---: | :---: | :---: |
| `id` | `—`   | `>`   | `>`   | `>`   |
| `+`  | `<`   | `>`   | `<`   | `>`   |
| `*`  | `<`   | `>`   | `>`   | `>`   |
| `$`  | `<`   | `<`   | `<`   | `—`   |

operator precedence table

```
       f|id > g|* > f|+ > g|+ > f|$
g|id > f|*  > ⤴
```

| .    | `id`  | `+`   | `*`   | `$`   |
| :--: | :---: | :---: | :---: | :---: |
| `f`  | `4`   | `2`   | `4`   | `0`   |
| `g`  | `5`   | `1`   | `3`   | `0`   |



```coffee

CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'scratch'
debug                     = CND.get_logger 'debug',     badge
help                      = CND.get_logger 'help',      badge


test_tsort = ->
  TS = CND.TSORT
  settings =
    strict:   yes
    prefixes: [ 'f|', 'g|', ]
  graph = TS.new_graph settings
  TS.link graph, 'id', '-', 'id'
  TS.link graph, 'id', '>', '+'
  TS.link graph, 'id', '>', '*'
  TS.link graph, 'id', '>', '$'
  TS.link graph, '+',  '<', 'id'
  TS.link graph, '+',  '>', '+'
  TS.link graph, '+',  '<', '*'
  TS.link graph, '+',  '>', '$'
  TS.link graph, '*',  '<', 'id'
  TS.link graph, '*',  '>', '+'
  TS.link graph, '*',  '>', '*'
  TS.link graph, '*',  '>', '$'
  TS.link graph, '$',  '<', 'id'
  TS.link graph, '$',  '<', '+'
  TS.link graph, '$',  '<', '*'
  TS.link graph, '$',  '-', '$'
  help nodes = TS.sort graph
  matcher = [ 'f|id', 'g|id', 'f|*', 'g|*', 'f|+', 'g|+', 'g|$', 'f|$' ]
  unless CND.equals nodes, matcher
    throw new Error """is: #{rpr nodes}
      expected:  #{rpr matcher}"""
  try
    TS.link graph, '$', '>', '$'
    TS.link graph, '$', '<', '$'
  catch error
    { message } = error
    if /^detected cycle involving node/.test message
      warn error
    else
      throw error

test_tsort()
```

```coffee
console.log '1',  ( TS.precedence_of graph, 'f|id' ) > ( TS.precedence_of graph, 'g|+'  ) # true
console.log '2',  ( TS.precedence_of graph, 'f|id' ) > ( TS.precedence_of graph, 'g|*'  ) # true
console.log '3',  ( TS.precedence_of graph, 'f|id' ) > ( TS.precedence_of graph, 'g|$'  ) # true
console.log '4',  ( TS.precedence_of graph, 'f|+'  ) < ( TS.precedence_of graph, 'g|id' ) # true
console.log '5',  ( TS.precedence_of graph, 'f|+'  ) > ( TS.precedence_of graph, 'g|+'  ) # true
console.log '6',  ( TS.precedence_of graph, 'f|+'  ) < ( TS.precedence_of graph, 'g|*'  ) # true
console.log '7',  ( TS.precedence_of graph, 'f|+'  ) > ( TS.precedence_of graph, 'g|$'  ) # true
console.log '8',  ( TS.precedence_of graph, 'f|*'  ) < ( TS.precedence_of graph, 'g|id' ) # true
console.log '9',  ( TS.precedence_of graph, 'f|*'  ) > ( TS.precedence_of graph, 'g|+'  ) # true
console.log '10', ( TS.precedence_of graph, 'f|*'  ) > ( TS.precedence_of graph, 'g|*'  ) # true
console.log '11', ( TS.precedence_of graph, 'f|*'  ) > ( TS.precedence_of graph, 'g|$'  ) # true
console.log '12', ( TS.precedence_of graph, 'f|$'  ) < ( TS.precedence_of graph, 'g|id' ) # true
console.log '13', ( TS.precedence_of graph, 'f|$'  ) < ( TS.precedence_of graph, 'g|+'  ) # true
console.log '14', ( TS.precedence_of graph, 'f|$'  ) < ( TS.precedence_of graph, 'g|*'  ) # true
```

### TSort API

* `@new_graph = ( settings ) ->`

* `@link = ( me, f, r, g ) ->`
* `@link_down = ( me, precedence, consequence ) ->`
* `@link_up = ( me, consequence, precedence ) -> @link_down me, precedence, consequence`
* `@register = ( me, names... ) ->`

* `@sort = ( me ) ->`

* `@get_precedences = ( me ) ->`
* `@precedence_of = ( me, name ) ->`

### Some TDOP Links

* [Pratt's original paper from 1973: http://hall.org.ua/halls/wizzard/pdf/Vaughan.Pratt.TDOP.pdf](http://hall.org.ua/halls/wizzard/pdf/Vaughan.Pratt.TDOP.pdf)
* [The same as an HTML page: http://tdop.github.io/](http://tdop.github.io/)
* [Simple Top-Down Parsing in Python: http://effbot.org/zone/simple-top-down-parsing.htm](http://effbot.org/zone/simple-top-down-parsing.htm)
* [Douglas Crockford on TDOP: http://javascript.crockford.com/tdop/tdop.html](http://javascript.crockford.com/tdop/tdop.html)

## XJSON

```coffee
  e         = new Set 'xy'
  e.add new Set 'abc'
  d         = [ 'A', 'B', e, ]
  info CND.XJSON.stringify d
  info CND.XJSON.parse CND.XJSON.stringify d
```

Output:

```coffee
["A","B",{"~isa":"set","%self":["x","y",{"~isa":"set","%self":["a","b","c"]}]}]
[ 'A', 'B', Set { 'x', 'y', Set { 'a', 'b', 'c' } } ]
```

## CND.TEXT.to_width

```
2
|北|2
|P |2
|Pe|2
|……|2
|P…|2
|a…|2
|x…|2
|a…|2
|a…|2
|……|2
|……|2
3
|北 |3
|P  |3
|Pe |3
|北…|3
|Pe…|3
|a …|3
|xa…|3
|àx…|4
|a⃝b…|4
|北…|3
|北…|3
4
|北  |4
|P   |4
|Pe  |4
|北京|4
|Pek…|4
|a n…|4
|xàx…|5
|àxa…|5
|a⃝b⃞c…|6
|北……|4
|北……|4
5
|北   |5
|P    |5
|Pe   |5
|北京 |5
|Peki…|5
|a ni…|5
|xàxa…|6
|àxáx…|7
|a⃝b⃞c⃟a…|8
|北京…|5
|北京…|5
10
|北        |10
|P         |10
|Pe        |10
|北京      |10
|Peking    |10
|a nice te…|10
|xàxáxâxãx…|14
|àxáxâxãxa…|14
|a⃝b⃞c⃟a⃝b⃞c⃟a⃝b⃞c…|18
|北京 (Pek…|10
|北京 (Pek…|10
15
|北             |15
|P              |15
|Pe             |15
|北京           |15
|Peking         |15
|a nice test to…|15
|xàxáxâxãxāxa̅xa…|21
|àxáxâxãxāxa̅xăx…|22
|a⃝b⃞c⃟a⃝b⃞c⃟a⃝b⃞c⃟a⃝b⃞c⃟…|25
|北京 (Peking) …|15
|北京 (Peking) …|15
20
|北                  |20
|P                   |20
|Pe                  |20
|北京                |20
|Peking              |20
|a nice test to see …|20
|xàxáxâxãxāxa̅xăxȧxax…|28
|àxáxâxãxāxa̅xăxȧxaxa…|28
|a⃝b⃞c⃟a⃝b⃞c⃟a⃝b⃞c⃟a⃝b⃞c⃟…|25
|北京 (Peking) 位於……|20
|北京 (Peking) 位於……|20
25
|北                       |25
|P                        |25
|Pe                       |25
|北京                     |25
|Peking                   |25
|a nice test to see the e…|25
|xàxáxâxãxāxa̅xăxȧxaxa̠xa̡xa…|35
|àxáxâxãxāxa̅xăxȧxaxa̠xa̡xa̢x…|36
|a⃝b⃞c⃟a⃝b⃞c⃟a⃝b⃞c⃟a⃝b⃞c⃟ |25
|北京 (Peking) 位於華北 (…|25
|北京 (Peking) 位於華北 (…|25
0         1         2         3
0123456789012345678901234567890123456789
a nice test to see the effect*
北京 (Peking) 位於華北 (North*
北京 (Peking) 位於華北 (North*
```