---
title: What's new in Prometheus 3.x!
author: Francis Begyn
date: \today
aspectratio: "169"
draft: true
---

# Intro

*  First major release since Prometheus 2.x (7 years)

---

# {.standout}

User interface

---

# User interface

* First thing that stands out, new UI!

---

# User interface

* New UI framework that offers modern look
* Also easier to maintain an make changes
* Mantine UI

---

# User interface

* Embeds a Promlens interface
* Helps with debugging and explain PromQL queries

----

# User interface

* better metrics explorer
* better overview in SD/targets tab
  * bit slower atm, but fixes are under way

----

# User interface

* still possible to go back to the old UI with feature flag

----

# Opentelemetry support

* Native OTEL support
* Support for UTF-8 in labels
  * better integration in OTEL format
* Multipple strategies for OTEL ingestion

----

# Native Histograms

* Experimental feature (not enabled by default)2
* Higher efficiency and lower cost alternative to Classic Histograms2
* Pre-set bucket boundaries based on exponential growth2

----

# Performance Improvements

* Significant efficiency improvements in CPU and memory usage2
* Comparison with previous versions (2.0.0 and 2.18.0)2

----

# Breaking Changes

* Removal of deprecated feature flags3
* Changes to configuration files, PromQL syntax, and scrape protocols1
* Range selections now left-open and right-closed3
* Agent mode stabilized with its own config flag3

----

# Migration and Upgrade Process

* Recommended upgrade path: v2.55 -> v3.012
* Migration guide available for smooth transition1
* Rollback only possible to v2.55, not earlier versions2

----

# Future Developments

* Ongoing work on OpenTelemetry compatibility2
* Native Histograms stability improvements2
* Further optimizations planned2

----

# Conclusion

* Available for download and testing2
* Community feedback and contributions welcomed2
