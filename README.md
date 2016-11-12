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






