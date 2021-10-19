# Code design

We have a really small team, with a really limited amount of time and hands to properly maintain a whole set of kubernetes resources, Grafana dashboards and Prometheus alerts used to monitor several different technologies that we run on production.

With that in mind, the [Monitoring Mixins](https://github.com/monitoring-mixins/docs/blob/master/design.pdf) project had a apealing offer that made this project move forward. As said in their design:

> ... it has become accepted wisdom that the developers of a given software package are best placed to operate said software, or at least construct the basic monitoring configuration

That means that we can reuse Grafana Dashboards and Prometheus Alerts created and maintained by the developers of those technologies we run in production. 
It not only assures a good level of quality but also alleviates the maintainance burden on our side.

### kube-prometheus

Kube-prometheus is the most popular project that bundles together several components, and their mixins, that are commonly used together to monitor applications that run on Kubernetes Clusters.

Inspired by [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus) design, we separate our libsonnet code in 3 main sections. By following their design, it's easy for us to propose new features upstream instead of maintaing them ourselves :) 

The sections are:

* `components` - Written as functions responsible for creating multiple objects representing kubernetes manifests. Responsible for providing configuration to deploy all resources necessary to run a certain technology in production, or at least everything that is necessary to monitor them. We aim to always re-use libraries that were developed upstream, but not all projects have developed their own mixins yet. On this section we can implement those missing bits, aiming to propose the implementation upstream some day.
* `addons` - Small snippets of code adding a small feature. Addons are meant to be used in object-oriented way like `local kp = (import 'kube-prometheus/main.libsonnet') + (import './addons/slack-alerting.libsonnet')`
* `lib` - Unfortunately not everything works out-of-the-box for us, and that's ok! We create small libs that specialize into changing small bits of configuration to override defaults from upstream that we're not interested in.
* TODO: `platforms` - Those will be `addons` specialized on adding support for different kubernetes platforms, e.g. `EKS` and `k3s`. Today we only officially support `GKE`.


---

## Road Map

We invision that this project will be responsible to deploy not only technologies responsible for collecting metrics, but all observability signals!
The code design must be re-thought as we introduce traces, logs and profiles collection.

When doing cloud-native Observability, it is crutial that we can easily correlate different signals quickly! To make this possible, we need to choose a Tech Stack that allows us to navigate through such signals.

Since we are betting on Prometheus for metrics, we'll go with a tech stack that do signal correlation through [Prometheus's Exemplars](https://grafana.com/blog/2021/03/31/intro-to-exemplars-which-enable-grafana-tempos-distributed-tracing-at-massive-scale/). So our next priorities are:

1. `Traces` - To be collected with [Jaeger](https://www.jaegertracing.io/) or [Tempo](https://grafana.com/oss/tempo/)
1. `Logs` - To be collected with [Loki](https://grafana.com/oss/loki/)
1. `Profiles` - To be collected with [Conprof](https://github.com/conprof/conprof)