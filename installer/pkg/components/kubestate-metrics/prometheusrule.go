package kubestateMetrics

import (
	"github.com/gitpod-io/observability/installer/pkg/common"
	"github.com/prometheus-operator/prometheus-operator/pkg/apis/monitoring/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/util/intstr"
)

func prometheusRule(ctx *common.RenderContext) ([]runtime.Object, error) {
	labelMap := common.Labels(Name, Component, App, Version)
	labelMap["prometheus"] = "k8s"
	labelMap["role"] = "alert-rules"
	return []runtime.Object{
		&v1.PrometheusRule{
			TypeMeta: metav1.TypeMeta{
				APIVersion: "monitoring.coreos.com/v1",
				Kind:       "PrometheusRule",
			},
			ObjectMeta: metav1.ObjectMeta{
				Name:      Name,
				Namespace: Namespace,
				Labels:    labelMap,
			},
			Spec: v1.PrometheusRuleSpec{
				Groups: []v1.RuleGroup{
					{
						Name: Name,
						Rules: []v1.Rule{
							{
								Alert: "KubeStateMetricsWatchErrors",
								Annotations: map[string]string{
									"description": "kube-state-metrics is experiencing errors at an elevated rate in watch operations. This is likely causing it to not be able to expose metrics about Kubernetes objects correctly or at all.",
									"runbook_url": "https://github.com/gitpod-io/runbooks/blob/main/runbooks/KubeStateMetricsWatchErrors.md",
									"summary":     "kube-state-metrics is experiencing errors in watch operations.",
								},
								Expr: intstr.IntOrString{
									StrVal: `|
(sum(rate(kube_state_metrics_watch_total{job="kube-state-metrics",result="error"}[5m]))
  /
sum(rate(kube_state_metrics_watch_total{job="kube-state-metrics"}[5m])))
> 0.01`,
								},
								For: "15m",
								Labels: map[string]string{
									"severity": "critical",
								},
							},
							{
								Alert: "KubeStateMetricsShardingMismatch",
								Annotations: map[string]string{
									"description": "kube-state-metrics pods are running with different --total-shards configuration, some Kubernetes objects may be exposed multiple times or not exposed at all.",
									"runbook_url": "https://github.com/gitpod-io/runbooks/blob/main/runbooks/KubeStateMetricsShardingMismatch.md",
									"summary":     "kube-state-metrics sharding is misconfigured.",
								},
								Expr: intstr.IntOrString{
									StrVal: `|
stdvar (kube_state_metrics_total_shards{job="kube-state-metrics"}) != 0`,
								},
								For: "15m",
								Labels: map[string]string{
									"severity": "critical",
								},
							},
							{
								Alert: "KubeStateMetricsShardsMissing",
								Annotations: map[string]string{
									"description": "kube-state-metrics shards are missing, some Kubernetes objects are not being exposed.",
									"runbook_url": "https://github.com/gitpod-io/runbooks/blob/main/runbooks/KubeStateMetricsShardsMissing.md",
									"summary":     "kube-state-metrics shards are missing.",
								},
								Expr: intstr.IntOrString{
									StrVal: `|
2^max(kube_state_metrics_total_shards{job="kube-state-metrics"}) - 1
  -
sum( 2 ^ max by (shard_ordinal) (kube_state_metrics_shard_ordinal{job="kube-state-metrics"}) )
!= 0`,
								},
								For: "15m",
								Labels: map[string]string{
									"severity": "critical",
								},
							},
						},
					},
				},
			},
		},
	}, nil
}
