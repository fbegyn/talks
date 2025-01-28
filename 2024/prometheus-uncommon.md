---
title: Prometheus (Un)common Knowledge
author: Francis Begyn
date: \today
aspectratio: "169"

---

# Intro

- Prometheus
- PromQL (Prometheus Query Language)

---

# {.standout}

Prometheus

---

# Prometheus

- Created in 2012 at SoundCloud
- Open-sourced in 2015
- Graduated to CNCF project status in 2018

---

# Prometheus

- Pull-based model
- Highly performant storage engine (on UNIX-compliant filesystems)
- Designed for reliability

---

# Prometheus

- Pull-based model
- Highly performant storage engine (on UNIX-compliant filesystems)
- Designed for reliability
- This means it’s not always 100% accurate
  - Compromise made to ensure system reliability

---

# {.standout}

Prometheus Components

---

# Prometheus Components

![Component Overview](./2024/images/prom-uncommon-knowledge/prometheus_overall_architecture.svg)

---

# {.standout}

Prometheus

---

# Prometheus and service discovery

![Prometheus SD](./2024/images/prom-uncommon-knowledge/prometheus_service_discovery_focus.svg)

---

# Service Discovery

- Created to handle dynamic environments
  - Containers
  - IaaC with “cattle” instead of “pets”
- Enables on-the-fly discovery of service instances

---

# Prometheus Targets and Service Discovery

```
- job_name: node-exporter
  puppetdb_sd_configs:
  - url: http://puppetdb.foo.bar:8080
    query: resources { type = "Package" and title = "node_exporter"
	                   and environment =~ "prod|dev|testing"}
    include_parameters: true
    port: 9100
```

---

# Labels ... ? What Are Labels?

> Use labels to differentiate the characteristics of what is being measured

- When querying: labels select the time series
- Internally in Prometheus: labels filter and manipulate metrics, targets, etc.

---

# Labels ... ? What Are Labels?

![promtheus relabel](./2024/images/prom-uncommon-knowledge/prometheus_relabel_flow.svg)

---

# Reserved Labels

- Allows dynamic changes to several scrape settings

- `__address__`: the actual endpoint Prometheus will fetch from
- `__metrics_path__`: the URL path appended to `__address__`
- `__scheme__`: the protocol scheme HTTP(S)
- `__scrape_interval__`: how often to scrape
- `__scrape_timeout__`: maximum duration allowed for a scrape

---

# Relabeler Webapp

![Relabeler QR](./2024/images/prom-uncommon-knowledge/relaber-site.png)

---

# {.standout}

Prometheus Exporters

---

# Prometheus Exporters

- Two types of exporters:
  1. Exporters that expose data of their own
  2. Exporters that expose data they collect from other targets

![Prometheus Exporter](./2024/images/prom-uncommon-knowledge/prometheus_exporter_focus.svg)

---

# Prometheus Exporters

- Collect data
- Expose collected data in Prometheus format

```
# HELP go_gc_duration_seconds A summary of the pause duration of garbage collection cycles.
# TYPE go_gc_duration_seconds summary
go_gc_duration_seconds{quantile="0"} 0.000138442
go_gc_duration_seconds{quantile="0.25"} 0.00022757
go_gc_duration_seconds_count 56699
# HELP go_goroutines Number of goroutines that currently exist.
# TYPE go_goroutines gauge
go_goroutines 14333
# HELP go_info Information about the Go environment.
# TYPE go_info gauge
go_info{version="go1.20.5"} 1
```

---

# {.standout}

Prometheus Remote Write

---

# Prometheus Remote Write

![Prometheus Remote Write](./2024/images/prom-uncommon-knowledge/prometheus_remote_focus.svg)

---

# {.standout}

PromQL

---

# PromQL

- Prometheus Query Language
- Functions, aggregators, selectors
- `{label1=value, label2=value, foo=bar}`
- See all time series of an instance: `{instance=<hostname>}`
- https://prometheus.io/docs/prometheus/latest/querying/basics/

---

# Querying

![Query Docs](./2024/images/prom-uncommon-knowledge/docs-query.png)

---

# PromQL

![PromQL Instant Query](./2024/images/prom-uncommon-knowledge/series_baseline.svg)

---

# Instant Query

Instant query `node_cpu_seconds`

![PromQL Instant Query](./2024/images/prom-uncommon-knowledge/series_instant_basics.svg)

---

# Range Query

Range query `node_cpu_seconds[10m]`

![PromQL Range Query](./2024/images/prom-uncommon-knowledge/series_range_query.svg)

---

# Functions

- Many functions like `avg, max, floor, ceil, round, rate, ...`
- This is generally where you see the trade-off between accuracy and reliability
  - `increase` function uses interpolation with `rate` under the hood

---

# {.standout}

Prometheus tooling

---

# promtool

- `promtool`: CLI interface for all things Prometheus
- allows for querying running Prometheus API
- validate Prometheus rule files
- validate Promehteus configurations
- run unit tests on queries and rule files
- many more things!

---

# amtool

- `amtool`: CLI interface for all things alertmanager
- allows for querying running Alertmanager API
- visualize the alert routing tree
- validate alertmanager configurations

---

# Promlabs guide

![promlabs YT](./2024/images/prom-uncommon-knowledge/promlabs-youtube.png)

---

Any Questions?

Francis Begyn

@fbegyn > Github/...

@fbegyn@social.begyn.be

https://francis.begyn.be
