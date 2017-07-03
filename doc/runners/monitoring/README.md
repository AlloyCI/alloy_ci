# GitLab Runner monitoring

GitLab Runner can be monitored using [Prometheus].

## Embedded Prometheus metrics

> The embedded HTTP Statistics Server with Prometheus metrics was
introduced in GitLab Runner 1.8.0.

The GitLab Runner is instrumented with native Prometheus
metrics, which can be exposed via an embedded HTTP server on the `/metrics`
path. The server - if enabled - can be scraped by the Prometheus monitoring
system or accessed with any other HTTP client.

The exposed information includes:

- Runner business logic metrics (e.g., the number of currently running builds)
- Go-specific process metrics (garbage collection stats, goroutines, memstats, etc.)
- general process metrics (memory usage, CPU usage, file descriptor usage, etc.)
- build version information

The following is an example of the metrics output in Prometheus'
text-based metrics exposition format:

```
# HELP ci_docker_machines The total number of machines created.
# TYPE ci_docker_machines counter
ci_docker_machines{type="created"} 0
ci_docker_machines{type="removed"} 0
ci_docker_machines{type="used"} 0
# HELP ci_docker_machines_provider The current number of machines in given state.
# TYPE ci_docker_machines_provider gauge
ci_docker_machines_provider{state="acquired"} 0
ci_docker_machines_provider{state="creating"} 0
ci_docker_machines_provider{state="idle"} 0
ci_docker_machines_provider{state="removing"} 0
ci_docker_machines_provider{state="used"} 0
# HELP ci_runner_builds The current number of running builds.
# TYPE ci_runner_builds gauge
ci_runner_builds{stage="prepare_script",state="running"} 1
# HELP ci_runner_version_info A metric with a constant '1' value labeled by different build stats fields.
# TYPE ci_runner_version_info gauge
ci_runner_version_info{architecture="amd64",branch="add-prometheus-metrics",built_at="2016-12-05 12:37:55 +0100 CET",go_version="go1.7.1",name="gitlab-ci-multi-runner",os="linux",revision="05c35a8",version="1.9.0~beta.19.g05c35a8"} 1
# HELP ci_ssh_docker_machines The total number of machines created.
# TYPE ci_ssh_docker_machines counter
ci_ssh_docker_machines{type="created"} 0
ci_ssh_docker_machines{type="removed"} 0
ci_ssh_docker_machines{type="used"} 0
# HELP ci_ssh_docker_machines_provider The current number of machines in given state.
# TYPE ci_ssh_docker_machines_provider gauge
ci_ssh_docker_machines_provider{state="acquired"} 0
ci_ssh_docker_machines_provider{state="creating"} 0
ci_ssh_docker_machines_provider{state="idle"} 0
ci_ssh_docker_machines_provider{state="removing"} 0
ci_ssh_docker_machines_provider{state="used"} 0
# HELP go_gc_duration_seconds A summary of the GC invocation durations.
# TYPE go_gc_duration_seconds summary
go_gc_duration_seconds{quantile="0"} 0.00030304800000000004
go_gc_duration_seconds{quantile="0.25"} 0.00038177500000000005
go_gc_duration_seconds{quantile="0.5"} 0.0009022510000000001
go_gc_duration_seconds{quantile="0.75"} 0.006189937
go_gc_duration_seconds{quantile="1"} 0.00880617
go_gc_duration_seconds_sum 0.016583181000000002
go_gc_duration_seconds_count 5
# HELP go_goroutines Number of goroutines that currently exist.
# TYPE go_goroutines gauge
go_goroutines 16
# HELP go_memstats_alloc_bytes Number of bytes allocated and still in use.
# TYPE go_memstats_alloc_bytes gauge
go_memstats_alloc_bytes 2.8288e+06
# HELP go_memstats_alloc_bytes_total Total number of bytes allocated, even if freed.
# TYPE go_memstats_alloc_bytes_total counter
go_memstats_alloc_bytes_total 7.973392e+06
# HELP go_memstats_buck_hash_sys_bytes Number of bytes used by the profiling bucket hash table.
# TYPE go_memstats_buck_hash_sys_bytes gauge
go_memstats_buck_hash_sys_bytes 1.444932e+06
# HELP go_memstats_frees_total Total number of frees.
# TYPE go_memstats_frees_total counter
go_memstats_frees_total 73317
# HELP go_memstats_gc_sys_bytes Number of bytes used for garbage collection system metadata.
# TYPE go_memstats_gc_sys_bytes gauge
go_memstats_gc_sys_bytes 423936
# HELP go_memstats_heap_alloc_bytes Number of heap bytes allocated and still in use.
# TYPE go_memstats_heap_alloc_bytes gauge
go_memstats_heap_alloc_bytes 2.8288e+06
# HELP go_memstats_heap_idle_bytes Number of heap bytes waiting to be used.
# TYPE go_memstats_heap_idle_bytes gauge
go_memstats_heap_idle_bytes 1.39264e+06
# HELP go_memstats_heap_inuse_bytes Number of heap bytes that are in use.
# TYPE go_memstats_heap_inuse_bytes gauge
go_memstats_heap_inuse_bytes 4.407296e+06
# HELP go_memstats_heap_objects Number of allocated objects.
# TYPE go_memstats_heap_objects gauge
go_memstats_heap_objects 23532
# HELP go_memstats_heap_released_bytes_total Total number of heap bytes released to OS.
# TYPE go_memstats_heap_released_bytes_total counter
go_memstats_heap_released_bytes_total 0
# HELP go_memstats_heap_sys_bytes Number of heap bytes obtained from system.
# TYPE go_memstats_heap_sys_bytes gauge
go_memstats_heap_sys_bytes 5.799936e+06
# HELP go_memstats_last_gc_time_seconds Number of seconds since 1970 of last garbage collection.
# TYPE go_memstats_last_gc_time_seconds gauge
go_memstats_last_gc_time_seconds 1.4768981425195277e+09
# HELP go_memstats_lookups_total Total number of pointer lookups.
# TYPE go_memstats_lookups_total counter
go_memstats_lookups_total 42
# HELP go_memstats_mallocs_total Total number of mallocs.
# TYPE go_memstats_mallocs_total counter
go_memstats_mallocs_total 96849
# HELP go_memstats_mcache_inuse_bytes Number of bytes in use by mcache structures.
# TYPE go_memstats_mcache_inuse_bytes gauge
go_memstats_mcache_inuse_bytes 4800
# HELP go_memstats_mcache_sys_bytes Number of bytes used for mcache structures obtained from system.
# TYPE go_memstats_mcache_sys_bytes gauge
go_memstats_mcache_sys_bytes 16384
# HELP go_memstats_mspan_inuse_bytes Number of bytes in use by mspan structures.
# TYPE go_memstats_mspan_inuse_bytes gauge
go_memstats_mspan_inuse_bytes 72320
# HELP go_memstats_mspan_sys_bytes Number of bytes used for mspan structures obtained from system.
# TYPE go_memstats_mspan_sys_bytes gauge
go_memstats_mspan_sys_bytes 98304
# HELP go_memstats_next_gc_bytes Number of heap bytes when next garbage collection will take place.
# TYPE go_memstats_next_gc_bytes gauge
go_memstats_next_gc_bytes 5.274438e+06
# HELP go_memstats_other_sys_bytes Number of bytes used for other system allocations.
# TYPE go_memstats_other_sys_bytes gauge
go_memstats_other_sys_bytes 1.2341e+06
# HELP go_memstats_stack_inuse_bytes Number of bytes in use by the stack allocator.
# TYPE go_memstats_stack_inuse_bytes gauge
go_memstats_stack_inuse_bytes 491520
# HELP go_memstats_stack_sys_bytes Number of bytes obtained from system for stack allocator.
# TYPE go_memstats_stack_sys_bytes gauge
go_memstats_stack_sys_bytes 491520
# HELP go_memstats_sys_bytes Number of bytes obtained by system. Sum of all system allocations.
# TYPE go_memstats_sys_bytes gauge
go_memstats_sys_bytes 9.509112e+06
# HELP process_cpu_seconds_total Total user and system CPU time spent in seconds.
# TYPE process_cpu_seconds_total counter
process_cpu_seconds_total 0.18
# HELP process_max_fds Maximum number of open file descriptors.
# TYPE process_max_fds gauge
process_max_fds 1024
# HELP process_open_fds Number of open file descriptors.
# TYPE process_open_fds gauge
process_open_fds 8
# HELP process_resident_memory_bytes Resident memory size in bytes.
# TYPE process_resident_memory_bytes gauge
process_resident_memory_bytes 2.3191552e+07
# HELP process_start_time_seconds Start time of the process since unix epoch in seconds.
# TYPE process_start_time_seconds gauge
process_start_time_seconds 1.47689813837e+09
# HELP process_virtual_memory_bytes Virtual memory size in bytes.
# TYPE process_virtual_memory_bytes gauge
process_virtual_memory_bytes 3.39746816e+08
```

Note that the lines starting with `# HELP` document the meaning of each exposed
metric. This metrics format is documented in Prometheus'
[Exposition formats](https://prometheus.io/docs/instrumenting/exposition_formats/)
specification.

These metrics are meant as a way for operators to monitor and gain insight into
GitLab Runners. For example, you may be interested if the load average increase
on your runner's host is related to an increase of processed builds or not. Or
you are running a cluster of machines to be used for the builds and you want to
track build trends to plan changes in your infrastructure.

### Learning more about Prometheus

To learn how to set up a Prometheus server to scrape this HTTP endpoint and
make use of the collected metrics, see Prometheus's [Getting
started](https://prometheus.io/docs/introduction/getting_started/) guide. Also
see the [Configuration](https://prometheus.io/docs/operating/configuration/)
section for more details on how to configure Prometheus, as well as the section
on [Alerting rules](https://prometheus.io/docs/alerting/rules/) and setting up
an [Alertmanager](https://prometheus.io/docs/alerting/alertmanager/) to
dispatch alert notifications.

## `pprof` HTTP endpoints

> `pprof` integration was introduced in GitLab Runner 1.9.0.

While having metrics about internal state of Runner process is useful
we've found that in some cases it would be good to check what is happening
inside of the Running process in real time. That's why we've introduced
the `pprof` HTTP endpoints.

`pprof` endpoints will be available via an embedded HTTP server on `/debug/pprof/`
path.

You can read more about using `pprof` in its [documentation][go-pprof].

## Configuration of the metrics HTTP server

> **Note:**
The metrics server exports data about the internal state of the
GitLab Runner process and should not be publicly available!

The metrics HTTP server can be configured in two ways:

- with a `metrics_server` global configuration option in `config.toml` file,
- with a `--metrics-server` command line option for the `run` command.

In both cases the option accepts a string with the format `[host]:<port>`,
where:

- `host` can be an IP address or a host name,
- `port` is a valid TCP port or symbolic service name (like `http`). We recommend to use port `9252` which is already [allocated in Prometheus](https://github.com/prometheus/prometheus/wiki/Default-port-allocations).

If the metrics server address does not contain a port, it will default to `9252`.

Examples of addresses:

- `:9252` - will listen on all IPs of all interfaces on port `9252`
- `localhost:9252` - will only listen on the loopback interface on port `9252`
- `[2001:db8::1]:http` - will listen on IPv6 address `[2001:db8::1]` on the HTTP port `80`

Remember that for listening on ports below `1024` - at least on Linux/Unix
systems - you need to have root/administrator rights.

Also please notice, that HTTP server is opened on selected `host:port`
**without any authorization**. If you plan to bind the metrics server
to a public interface then you should consider to use your firewall to
limit access to this server or add a HTTP proxy which will add the
authorization and access control layer.

[go-pprof]: https://golang.org/pkg/net/http/pprof/
[prometheus]: https://prometheus.io
