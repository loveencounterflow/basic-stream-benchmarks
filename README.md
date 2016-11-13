
# basic-stream-benchmarks

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Installation](#installation)
- [Running](#running)
  - [In 'plain' NodeJS](#in-plain-nodejs)
  - [In DevTools](#in-devtools)
- [Building](#building)
- [Results](#results)
  - [Observations](#observations)
  - [Numbers](#numbers)
  - [Flamegraphs](#flamegraphs)
- [ToDo](#todo)
- [Acknowledgements](#acknowledgements)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


## Installation

```bash
git clone https://github.com/loveencounterflow/basic-stream-benchmarks.git
cd basic-stream-benchmarks
npm install
```

Additionally, you may want to

```bash
npm install -g devtool
```

so you can run the code inside Chromium DevTools.


## Running

### In 'plain' NodeJS

```bash
node lib/main.js
```

This will run a few test cases and produce flamegraph SVGs.


### In DevTools

```bash
devtool lib/main.js
```

This will start Chromium DevTools and run the same code as with plain NodeJS, above, but results in
interactive profiles.

## Building

If you have CoffeeScript installed and want to fiddle with source, you can re-build with

```bash
npm run build
```

## Results

### Observations

* sync mode is faster than async

* devtools' instrumented runs are naturally slower than NodeJS runs

* in async mode, call stacks have a conatant height; in sync mode, call stacks grow with the length of
  the pipeline. Devtools errors out way below 100 strem transforms / pipeline, NodeJS manages 300 and
  maybe more.



### Numbers

| job                       | n    | mode  | dt     | bps         | ips        | Δdt    | Δbps     | Δips    |
| ---:                      | ---: | ---:  | ---:   | ---:        | ---:       | ---:   | ---:     | ---:    |
| n=0,size=long,mode=sync   | 0    | sync  | 1.966  | 718,964.395 | 24,806.714 |        |          |         |
| n=1,size=long,mode=sync   | 1    | sync  | 2.742  | 515,493.800 | 17,786.287 | -0.776 | -203,471 | -7,020  |
| n=10,size=long,mode=sync  | 10   | sync  | 6.682  | 211,536.067 | 7,298.713  | -0.472 | -50,743  | -1,751  |
| n=20,size=long,mode=sync  | 20   | sync  | 10.784 | 131,072.329 | 4,522.441  | -0.441 | -29,395  | -1,014  |
| n=40,size=long,mode=sync  | 40   | sync  | 19.103 | 73,992.776  | 2,553.002  | -0.428 | -16,124  | -556    |
| n=0,size=long,mode=async  | 0    | async | 2.097  | 674,050.548 | 23,257.034 |        |          |         |
| n=1,size=long,mode=async  | 1    | async | 4.413  | 320,300.023 | 11,051.439 | -2.316 | -353,751 | -12,206 |
| n=10,size=long,mode=async | 10   | async | 10.733 | 131,695.146 | 4,543.930  | -0.864 | -54,236  | -1,871  |
| n=20,size=long,mode=async | 20   | async | 16.113 | 87,723.205  | 3,026.749  | -0.701 | -29,316  | -1,012  |
| n=40,size=long,mode=async | 40   | async | 27.659 | 51,103.944  | 1,763.260  | -0.639 | -15,574  | -537    |

Format of **columns Δdt, Δbps and Δips**: Numbers represent changes in wall clock time taken, bytes per
second and items (lines) per second **relative to the count of minimal no-op transforms** (column **n**).
Positive numbers in the  indicate gains, while negative ones indicate losses; therefore, a Δdt of -0.776
indicates an **increase** of 0.776 seconds per transform added; a Δbps of -203,471 indicates a **decrease**
of 203k bytes per transform added, and so on.

Tested against file `test-data/Unicode-NamesList.txt`, which has 1,413,484 bytes of ASCII-only text in
48,770 lines.


<!--

```bash
perf record -F 99 -g -- node ~/io/basic-stream-benchmarks/lib/main.js && \
perf script > out.perf && \
~/bin/FlameGraph/stackcollapse-perf.pl out.perf > out.folded && \
~/bin/FlameGraph/flamegraph.pl out.folded > flamegraph.svg
```

```bash
npm install -g flamegraph
npm install v8-profiler
```

```bash
npm run build && node lib/main.js
cat profile-n\:1.json | flamegraph -t cpuprofile > flamegraph.svg
cat profile-n\:5.json | flamegraph -t cpuprofile > flamegraph-n5-async-short.svg
```

 -->

### Flamegraphs


n=0, size=long, mode=async: <img src="https://cdn.rawgit.com/loveencounterflow/basic-stream-benchmarks/master/flamegraph-n=0,size=long,mode=async.png" width=200>;
n=0, size=long, mode=sync: <img src="https://cdn.rawgit.com/loveencounterflow/basic-stream-benchmarks/master/flamegraph-n=0,size=long,mode=sync.png" width=200>

n=10, size=long, mode=async: <img src="https://cdn.rawgit.com/loveencounterflow/basic-stream-benchmarks/master/flamegraph-n=10,size=long,mode=async.png" width=200>;
n=10, size=long, mode=sync: <img src="https://cdn.rawgit.com/loveencounterflow/basic-stream-benchmarks/master/flamegraph-n=10,size=long,mode=sync.png" width=200>

n=20, size=long, mode=async: <img src="https://cdn.rawgit.com/loveencounterflow/basic-stream-benchmarks/master/flamegraph-n=20,size=long,mode=async.png" width=200>;
n=20, size=long, mode=sync: <img src="https://cdn.rawgit.com/loveencounterflow/basic-stream-benchmarks/master/flamegraph-n=20,size=long,mode=sync.png" width=200>

n=40, size=long, mode=async: <img src="https://cdn.rawgit.com/loveencounterflow/basic-stream-benchmarks/master/flamegraph-n=40,size=long,mode=async.png" width=200>;
n=40, size=long, mode=sync: <img src="https://cdn.rawgit.com/loveencounterflow/basic-stream-benchmarks/master/flamegraph-n=40,size=long,mode=sync.png" width=200>

n=100, size=long, mode=async: <img src="https://cdn.rawgit.com/loveencounterflow/basic-stream-benchmarks/master/flamegraph-n=100,size=long,mode=async.png" width=200>;
n=100, size=long, mode=sync: <img src="https://cdn.rawgit.com/loveencounterflow/basic-stream-benchmarks/master/flamegraph-n=100,size=long,mode=sync.png" width=200>


## ToDo

* [ ] refactor exported / not exported methods in main
* [ ] logging: one result per line
* [ ] TAP, PipeDreams?
* [ ] test `process.nextTick` vs `setImmediate`
* [ ] test streaming from file vs. manually feeding input with `input.push` in loop

## Acknowledgements

Flamegraphs made with [thlorenz/flamegraph](https://github.com/thlorenz/flamegraph) which is based on
[brendangregg/FlameGraph](https://github.com/brendangregg/FlameGraph). Flamegraph SVGs converted to
PNGs with [domenic/svg2png](https://github.com/domenic/svg2png).

