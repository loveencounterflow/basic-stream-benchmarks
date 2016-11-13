# basic-stream-benchmarks
assessing throughput performance of NodeJS streams



* sync mode is faster than async

* devtools' instremented runs are naturally slower than NodeJS runs

* in async mode, call stacks have a conatant height; in sync mode, call stacks grow with the length of
  the pipeline. Devtools errors out way below 100 strem transforms / pipeline, NodeJS manages 300 and
  maybe more.




# ToDo

* [ ] refactor exported / not exported methods in main
* [ ] logging: one result per line
* [ ] TAP, PipeDreams?
* [ ] test `process.nextTick` vs `setImmediate`
* [ ] test streaming from file vs. manually feeding input with `input.push` in loop



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


![](https://cdn.rawgit.com/loveencounterflow/basic-stream-benchmarks/master/flamegraph-n5-async-short.svg)






