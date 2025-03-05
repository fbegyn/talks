---
title: Prometheus service discovery with consul/puppet
author: Francis Begyn
date: 2025-03-06
aspectratio: "169"
draft: true
---

# Prometheus service discovery with consul/puppet

---

## Exporters

* Expose prometheus metrics
  * service exporter: expose metrics of a service locally <!-- .element class="fragment" data-fragment-index="1" -->
  * multi-target exporter: exposes metrics of an external service <!-- .element class="fragment" data-fragment-index="1" -->

Notes:
* Prometheus exporters are a crucial tool for prometheus. Without them there is
  no data*
* There are 2 types of exporters. service exporters that expose metrics of an on
  host system and multi-target exporters which will fetch data and metrics from
  an external services and hosts.

---

* Exporters are installed through puppet

```puppet [1-5]
Package { ... }

Service { ... }

File { .... } # templates exporter config file

prometheus::service { ... }
```

---

* Installing/configuring exporter is more about the exporter then Prometheus 
* Basic understanding of the "monitored" service needed <!-- .element class ="fragment" data-fragment-index="1" -->

Notes:
Running prometheus exporters is really more about the monitored service then it
about Prometheus. To setup an exporter some knowledge of Prometheus is required
(mainly that it is a pulled based system), but more important is knowledge of the
service you want to monitor.

You need to know how and what you want to monitor

---

## service disocvery

* crucial part for Prometheus
* Prometheus is designed with dynamic environments in mind
* a "static" landscape (VM with puppet, ansible, ...) <!-- .element class="fragment" data-fragment-index="1" -->
* a dynamic landscape (Openshift, Kubernes, cloud, ...) <!-- .element class="fragment" data-fragment-index="2" -->

---

* Puppet offers service discovery as well (through consul)

```puppet [7]
Package { ... }

Service { ... }

File { .... } # templates exporter config file

prometheus::service { ... } # custom class
```

Notes:

The custom class will create a consul service definition for the defined service.
Consul will in it's turn register this service against the cluster and make it
accessible for all things to use it.
It's quite important to ship the right metadata through consul.

---

Let's take a look at the custom class definition:

```ruby [2-3|4|5-6|7-9]
define prometheus::service (
  Stdlib::Port                    $port,
  String                          $service_name    = $name,
  Array[String]                   $tags            = [],
  String                          $scheme          = 'http',
  Optional[String]                $token           = undef,
  Hash[String, String]            $labels          = {},
  Hash[String, String]            $params          = {},
  Hash[String, String]            $meta            = {},
)
```

Notes:
Each service needs a unique name (puppet constraint). We can override the service
name, this comes in handy when we run multiple instances of the same
exporter/service on a single host and we need to enforce the unique puppet name.
In that case we can overrule it.

Tags in consul is how applications can discovery services through consul. We can
list several tags and if the service matches these, it'll return the service and
the underlaying instances of it.

Scheme and token are general settings for the exporter, but each instance can
overrule these settings through relabeling and metadata.

Several keys for metadata setting on the service. This is where the dynamic power
of service discovery comes from.

--

And then at the template for consul:

```hcl [2|3|4|5-9|10-23]
service {
  name = "<%= @service_name -%>"
  id = "<%= @name -%>:<%= @port -%>"
  port = <%= @port %>
  tags = [
  <%- @_tags.each do |tagitem| -%>
    "<%= tagitem %>",
  <%- end -%>
  ]
  meta = {
  <%- if @scheme -%>
    "scheme" = "<%= @scheme -%>",
  <%- end -%>
  <%- @labels.each do |lab, value| -%>
    "label_<%= lab %>" = "<%= value -%>",
  <%- end -%>
  <%- @params.each do |param, value| -%>
    "param_<%= param %>" = "<%= value -%>",
  <%- end -%>
  <%- @meta.each do |key, value| -%>
    "<%= key %>" = "<%= value -%>",
  <%- end -%>
  }
}
```

Notes:

We first set the service name. This is the name you will see in the consul
service cata log at the top level. This service name should be quite general like
prometheus, alertmanager, tomcat, |application|, ...

Each "instance" of a service needs it's own unique ID. Here we combine the name
of the resource (which should be unique anyways) with the port on which the
service runs to make it more unique. Here puppet helps us with fullfilling the
unique constraint.

Tags in consul is how applications can discovery services through consul. We can
list several tags and if the service matches these, it'll return the service and
the underlaying instances of it.

Lastly, but most importantly, we embed some metadata with the service. This
metadat can vary on each instance on a service. This metadata can vary depending
on the service, but we've shaped the custom class definition a bit so it's aimed
at Prometheus.
labels get prefixed with `label_` so it's easy to run a labelmap in Prometheus
params get prefixed with `param_` so it's easy to run a labelmap in Prometheus
and there is a `meta` hash that allows us to just embed custom keys in the
metadata that don't match the others.

---

What is visible in consul:

![overview](/static/talks/img/2025/exporter-service-consul-overview.webp)

--

What is visible in consul:

![service](/static/talks/img/2025/exporter-service-consul-service.webp)

--

What is visible in consul:

![metadata](/static/talks/img/2025/exporter-service-consul-metadata.webp)

---

## Get it in prometheus

Notes:

So now that we have a service up and running in Consul, how can we leverage the
power of Prometheus to get this running dynamically 

---

Taking the exporter from earlier screenshots

```yaml [1|2-3|11-18]
- job_name: powerstore-exporter
  scrape_interval: 30s
  scrape_timeout: 10s
  metrics_path: /metrics
  scheme: http
  relabel_configs:
  - separator: ;
    regex: __meta_consul_service_metadata_label_(.*)
    replacement: ${1}
    action: labelmap
  consul_sd_configs:
  - server: localhost:8500
    scheme: http
    refresh_interval: 5m
    tags:
    - prom-service
    - powerstore-exporter
    follow_redirects: true
```

---

Job config with consul SD leads to the following result:

![sd](/static/talks/img/2025/exporter-service-prom-sd.webp)

Notes:
See all the metadata tags for each component of consul, the node, service and
even the internal metadata from consul is visible (datacenter, ip, ...)

We can use these labels in relabelings to dynamically compose jobs/targets.

---

## relabeling

Let's take a look at the most basic for the previous exporter.

```yaml [7-12|13-18]
- job_name: powerstore-exporter
  scrape_interval: 30s
  scrape_timeout: 10s
  metrics_path: /metrics
  scheme: http
  relabel_configs:
  - source_labels: [__meta_consul_service_metadata_label_instance]
    regex: "(.*)"
    seperator: ";"
    target_label: instance
    replacement: ${1}
    action: replace
  - source_labels: [__meta_consul_service_metadata_label_stanza_env]
    seperator: ";"
    regex: "(.*)"
    replacement: ${1}
    target_label: stanza_env
    action: replace
  consul_sd_configs:
  - server: localhost:8500
    scheme: http
    refresh_interval: 5m
    tags:
    - prom-service
    - powerstore-exporter
    follow_redirects: true
```

Notes:
This is the most basic setup. It takes the instance and env metadata we set
on the service and sets it as a label.

You can list multiple source labels, which will be combined into a single
string, seperated by the seperator character. On this single string you can apply
a regex and use the capture groups in this regex in the replacement keyword.

Eventually the target label (notice singular) is replace with the result in
replacement.

(look at instance and env)

As you can imagine, this become quite repetitive so Prometheus makes this a bit
easier.

---

Lots of repetition, let's take a look at something better


```yaml [6-10]
- job_name: powerstore-exporter
  scrape_interval: 30s
  scrape_timeout: 10s
  metrics_path: /metrics
  scheme: http
  relabel_configs:
  - separator: ;
    regex: __meta_consul_service_metadata_label_(.*)
    replacement: ${1}
    action: labelmap
  consul_sd_configs:
  - server: localhost:8500
    scheme: http
    refresh_interval: 5m
    tags:
    - prom-service
    - powerstore-exporter
    follow_redirects: true
```

[https://prometheus.io/docs/prometheus/latest/configuration/configuration/#relabel_config](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#relabel_config) <!-- .element class="fragment" data-fragment-index="2" -->

Notes:
This uses the labelmap action. This action works a bit different from the replace
action since it doesn't take source or targets labels. Instead it matches the
regex against all discovered labels and uses the capture groups from the regex in
the replacement. Every matching discovered label becomes it's own label in
prometheus.

---

The result of the previous setup

![sd](/static/talks/img/2025/exporter-service-prom-sd-result.webp)

---

## unlimited posibilities

This becomes very powerfull when fully utilized and comprehended

Imagine the following service <!-- .element class="fragment" data-fragment-index="1" -->

Has several API endpoints (prometheus/health/info/ready/...)<!-- .element class="fragment" data-fragment-index="2" -->

Each endpoint is capable of being monitored <!-- .element class="fragment" data-fragment-index="2" -->

But requires specific modules to be configured <!-- .element class="fragment" data-fragment-index="2" -->

---

Assumptions:
* blackbox exporter has a `service-info` and `service-health` module
* json exporter has a `service-health` module

---

First we register the service

```ruby [2-4|6-9,18|10-14,19|15,20|21-22]
prometheus::service { "service_${application}_${tomcat_port}":
  service_name => "service_${application}", # optional service name, defaults to $title
  port         => $service_port,
  tags         => ['service'],
  params       => {
    info_path              => "/${application_basepath}${http_probe}",
    info_scrape_interval   => $probe_check_interval,
    info_scrape_timeout    => $probe_retry_interval,
    blackbox_info_module   => 'service-info',
    health_path            => "/${application_basepath}${healthprobe_path}",
    health_scrape_interval => $health_check_interval,
    health_scrape_timeout  => $health_retry_interval,
    blackbox_health_module => 'service-health',
    json_health_module     => 'service-health',
    prometheus_path        => "/${application_basepath}/prometheus",
  },
  meta         => {
    info_enabled       => $http_probe_enabled,
    health_enabled     => $health_probe_enabled,
    prometheus_enabled => $prometheus,
    display_name       => $display_name,
  },
  labels       => {
    application        => $application,
  },
}
```

---

First we configure the service discovery

```yaml [11-18]
- job_name: service
  scrape_interval: 30s
  scrape_timeout: 10s
  metrics_path: /metrics
  scheme: http
  relabel_configs:
  - separator: ;
    regex: __meta_consul_service_metadata_label_(.*)
    replacement: ${1}
    action: labelmap
  consul_sd_configs:
  - server: localhost:8500
    scheme: http
    refresh_interval: 5m
    tags:
    - prom-service
    - service
    follow_redirects: true
```

---

A first job just to get the prometheus metrics endpoint

```yaml [7-9|4,10-11]
- job_name: service
  scrape_interval: 30s
  scrape_timeout: 10s
  metrics_path: /metrics # this no longer matters
  scheme: http
  relabel_configs:
  - source_labels: [__meta_consul_service_metadata_prometheus_enabled]
    regex: "True"
    action: keep
  - source_labels: [__meta_consul_service_metadata_param_prometheus_path]
    target_label: __metrics_path__
  - separator: ;
    regex: __meta_consul_service_metadata_label_(.*)
    replacement: ${1}
    action: labelmap
  consul_sd_configs:
  - server: localhost:8500
    scheme: http
    refresh_interval: 5m
    tags:
    - prom-service
    - service
    follow_redirects: true
```

Notes:
we only want to keep the target with prometheus enabled and relabel to the
correct metrics path.

---

A second job for the info endpoint

A quick refersher of the info metadata in consul

```ruby
info_path              => "/${application_basepath}${http_probe}",
info_scrape_interval   => $probe_check_interval,
info_scrape_timeout    => $probe_retry_interval,
blackbox_info_module   => 'service-info',
```

--

A second job for the info endpoint

```yaml [7-9|10-13|18-22|23-25|26-30]
- job_name: service-info
  ...
  consul_sd_configs:
  - server: localhost:8500
    ...
  relabel_configs:
  - source_labels: [__meta_consul_service_metadata_info_enabled]
    regex: "True"
    action: keep
  # deals with scrape interval and timeout
  - regex: "__meta_consul_service_metadata_param_info(.*)"
    replacement: "_${1}__"
    action: labelmap
  - separator: ;
    regex: __meta_consul_service_metadata_label_(.*)
    replacement: ${1}
    action: labelmap
  # set target to http://<host>:<port><info path>
  - source_labels: [__meta_consul_node, __path__, __meta_consul_service_port]
    regex: "(.*);(.*);(.*)"
    target_label: __param_target
    replacement: "http://${1}:${3}${2}"
  # set blackbox module param
  - source_labels: [_meta_consul_service_metadata_param_blackbox_info_module]
    target_label: __param_module
  # set the blackbox exporter address
  - separator: ;
    target_label: __address__
    replacement: blackboxexporter:9115
    action: replace
```

Notes:
we only want to keep the target with prometheus enabled and relabel to the
correct metrics path.

---

And we can do the same for other endpoints in the metadata

---

## happy relabeling and service configuration!

Any questions?
