# basic-stream-benchmarks
assessing throughput performance of NodeJS streams



* sync mode is faster than async

* devtools' instremented runs are naturally slower than NodeJS runs

* in async mode, call stacks have a conatant height; in sync mode, call stacks grow with the length of
  the pipeline. Devtools errors out way below 100 strem transforms / pipeline, NodeJS manages 300 and
  maybe more.


# Results

| job                       | n    | mode  | dt     | bytes   | items | bps        | ips       | Δdt    | Δbps     | Δips    |
| ---:                      | ---: | ---:  | ---:   | ---:    | ---:  | ---:       | ---:      | ---:   | ---:     | ---:    |
| n=0,size=long,mode=sync   | 0    | sync  | 1.966  | 1413484 | 48770 | 718964.395 | 24806.714 |        |          |         |
| n=1,size=long,mode=sync   | 1    | sync  | 2.742  | 1413484 | 48770 | 515493.800 | 17786.287 | -0.776 | -203,471 | -7,020  |
| n=10,size=long,mode=sync  | 10   | sync  | 6.682  | 1413484 | 48770 | 211536.067 | 7298.713  | -0.472 | -50,743  | -1,751  |
| n=20,size=long,mode=sync  | 20   | sync  | 10.784 | 1413484 | 48770 | 131072.329 | 4522.441  | -0.441 | -29,395  | -1,014  |
| n=40,size=long,mode=sync  | 40   | sync  | 19.103 | 1413484 | 48770 | 73992.776  | 2553.002  | -0.428 | -16,124  | -556    |
| n=0,size=long,mode=async  | 0    | async | 2.097  | 1413484 | 48770 | 674050.548 | 23257.034 |        |          |         |
| n=1,size=long,mode=async  | 1    | async | 4.413  | 1413484 | 48770 | 320300.023 | 11051.439 | -2.316 | -353,751 | -12,206 |
| n=10,size=long,mode=async | 10   | async | 10.733 | 1413484 | 48770 | 131695.146 | 4543.930  | -0.864 | -54,236  | -1,871  |
| n=20,size=long,mode=async | 20   | async | 16.113 | 1413484 | 48770 | 87723.205  | 3026.749  | -0.701 | -29,316  | -1,012  |
| n=40,size=long,mode=async | 40   | async | 27.659 | 1413484 | 48770 | 51103.944  | 1763.260  | -0.639 | -15,574  | -537    |




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


# ToDo

* [ ] refactor exported / not exported methods in main
* [ ] logging: one result per line
* [ ] TAP, PipeDreams?
* [ ] test `process.nextTick` vs `setImmediate`
* [ ] test streaming from file vs. manually feeding input with `input.push` in loop

# Acknowledgements


Flamegraphs made with [thlorenz/flamegraph](https://github.com/thlorenz/flamegraph) which is based on
[brendangregg/FlameGraph](https://github.com/brendangregg/FlameGraph).

