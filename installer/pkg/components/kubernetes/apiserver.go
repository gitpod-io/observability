package kubernetes

import (
	"fmt"

	monitoringv1 "github.com/prometheus-operator/prometheus-operator/pkg/apis/monitoring/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"

	"github.com/gitpod-io/observability/installer/pkg/common"
)

func serviceMonitorAPIServer(ctx *common.RenderContext) ([]runtime.Object, error) {
	labels := map[string]string{
		"app.kubernetes.io/component": "kubelet",
		"app.kubernetes.io/name":      "kubelet",
		"app.kubernetes.io/part-of":   App,
	}

	return []runtime.Object{
		&monitoringv1.ServiceMonitor{
			TypeMeta: metav1.TypeMeta{
				APIVersion: "monitoring.coreos.com/v1",
				Kind:       "ServiceMonitor",
			},
			ObjectMeta: metav1.ObjectMeta{
				Name:      fmt.Sprintf("%s-apiserver", Name),
				Namespace: Namespace,
				Labels:    labels,
				Annotations: map[string]string{
					"argocd.argoproj.io/sync-options": "Replace=true",
				},
			},
			Spec: monitoringv1.ServiceMonitorSpec{
				JobLabel: "app.kubernetes.io/name",
				Selector: metav1.LabelSelector{
					MatchLabels: map[string]string{
						"app.kubernetes.io/name": "kubelet",
					},
				},
				NamespaceSelector: monitoringv1.NamespaceSelector{
					MatchNames: []string{"kube-system"},
				},
				Endpoints: []monitoringv1.Endpoint{
					{
						BearerTokenFile: "/var/run/secrets/kubernetes.io/serviceaccount/token",
						HonorLabels:     true,
						Port:            "https-metrics",
						Interval:        "60s",
						Scheme:          "https",
						TLSConfig: &monitoringv1.TLSConfig{
							SafeTLSConfig: monitoringv1.SafeTLSConfig{
								InsecureSkipVerify: true,
							},
						},
						RelabelConfigs: []*monitoringv1.RelabelConfig{
							{
								SourceLabels: []monitoringv1.LabelName{"__metrics_path__"},
								TargetLabel:  "metrics_path",
							},
						},
						MetricRelabelConfigs: append([]*monitoringv1.RelabelConfig{
							{
								Action:       "drop",
								Regex:        "kubelet_(pod_worker_latency_microseconds|pod_start_latency_microseconds|cgroup_manager_latency_microseconds|pod_worker_start_latency_microseconds|pleg_relist_latency_microseconds|pleg_relist_interval_microseconds|runtime_operations|runtime_operations_latency_microseconds|runtime_operations_errors|eviction_stats_age_microseconds|device_plugin_registration_count|device_plugin_alloc_latency_microseconds|network_plugin_operations_latency_microseconds)",
								SourceLabels: []monitoringv1.LabelName{"__name__"},
							},
							{
								Action:       "drop",
								Regex:        "scheduler_(e2e_scheduling_latency_microseconds|scheduling_algorithm_predicate_evaluation|scheduling_algorithm_priority_evaluation|scheduling_algorithm_preemption_evaluation|scheduling_algorithm_latency_microseconds|binding_latency_microseconds|scheduling_latency_seconds)",
								SourceLabels: []monitoringv1.LabelName{"__name__"},
							},
							{
								Action:       "drop",
								Regex:        "apiserver_(request_count|request_latencies|request_latencies_summary|dropped_requests|storage_data_key_generation_latencies_microseconds|storage_transformation_failures_total|storage_transformation_latencies_microseconds|proxy_tunnel_sync_latency_secs|longrunning_gauge|registered_watchers)",
								SourceLabels: []monitoringv1.LabelName{"__name__"},
							},
							{
								Action:       "drop",
								Regex:        "kubelet_docker_(operations|operations_latency_microseconds|operations_errors|operations_timeout)",
								SourceLabels: []monitoringv1.LabelName{"__name__"},
							},
							{
								Action:       "drop",
								Regex:        "reflector_(items_per_list|items_per_watch|list_duration_seconds|lists_total|short_watches_total|watch_duration_seconds|watches_total)",
								SourceLabels: []monitoringv1.LabelName{"__name__"},
							},
							{
								Action:       "drop",
								Regex:        "etcd_(helper_cache_hit_count|helper_cache_miss_count|helper_cache_entry_count|object_counts|request_cache_get_latencies_summary|request_cache_add_latencies_summary|request_latencies_summary)",
								SourceLabels: []monitoringv1.LabelName{"__name__"},
							},
							{
								Action:       "drop",
								Regex:        "transformation_(transformation_latencies_microseconds|failures_total)",
								SourceLabels: []monitoringv1.LabelName{"__name__"},
							},
							{
								Action:       "drop",
								Regex:        "(admission_quota_controller_adds|admission_quota_controller_depth|admission_quota_controller_longest_running_processor_microseconds|admission_quota_controller_queue_latency|admission_quota_controller_unfinished_work_seconds|admission_quota_controller_work_duration|APIServiceOpenAPIAggregationControllerQueue1_adds|APIServiceOpenAPIAggregationControllerQueue1_depth|APIServiceOpenAPIAggregationControllerQueue1_longest_running_processor_microseconds|APIServiceOpenAPIAggregationControllerQueue1_queue_latency|APIServiceOpenAPIAggregationControllerQueue1_retries|APIServiceOpenAPIAggregationControllerQueue1_unfinished_work_seconds|APIServiceOpenAPIAggregationControllerQueue1_work_duration|APIServiceRegistrationController_adds|APIServiceRegistrationController_depth|APIServiceRegistrationController_longest_running_processor_microseconds|APIServiceRegistrationController_queue_latency|APIServiceRegistrationController_retries|APIServiceRegistrationController_unfinished_work_seconds|APIServiceRegistrationController_work_duration|autoregister_adds|autoregister_depth|autoregister_longest_running_processor_microseconds|autoregister_queue_latency|autoregister_retries|autoregister_unfinished_work_seconds|autoregister_work_duration|AvailableConditionController_adds|AvailableConditionController_depth|AvailableConditionController_longest_running_processor_microseconds|AvailableConditionController_queue_latency|AvailableConditionController_retries|AvailableConditionController_unfinished_work_seconds|AvailableConditionController_work_duration|crd_autoregistration_controller_adds|crd_autoregistration_controller_depth|crd_autoregistration_controller_longest_running_processor_microseconds|crd_autoregistration_controller_queue_latency|crd_autoregistration_controller_retries|crd_autoregistration_controller_unfinished_work_seconds|crd_autoregistration_controller_work_duration|crdEstablishing_adds|crdEstablishing_depth|crdEstablishing_longest_running_processor_microseconds|crdEstablishing_queue_latency|crdEstablishing_retries|crdEstablishing_unfinished_work_seconds|crdEstablishing_work_duration|crd_finalizer_adds|crd_finalizer_depth|crd_finalizer_longest_running_processor_microseconds|crd_finalizer_queue_latency|crd_finalizer_retries|crd_finalizer_unfinished_work_seconds|crd_finalizer_work_duration|crd_naming_condition_controller_adds|crd_naming_condition_controller_depth|crd_naming_condition_controller_longest_running_processor_microseconds|crd_naming_condition_controller_queue_latency|crd_naming_condition_controller_retries|crd_naming_condition_controller_unfinished_work_seconds|crd_naming_condition_controller_work_duration|crd_openapi_controller_adds|crd_openapi_controller_depth|crd_openapi_controller_longest_running_processor_microseconds|crd_openapi_controller_queue_latency|crd_openapi_controller_retries|crd_openapi_controller_unfinished_work_seconds|crd_openapi_controller_work_duration|DiscoveryController_adds|DiscoveryController_depth|DiscoveryController_longest_running_processor_microseconds|DiscoveryController_queue_latency|DiscoveryController_retries|DiscoveryController_unfinished_work_seconds|DiscoveryController_work_duration|kubeproxy_sync_proxy_rules_latency_microseconds|non_structural_schema_condition_controller_adds|non_structural_schema_condition_controller_depth|non_structural_schema_condition_controller_longest_running_processor_microseconds|non_structural_schema_condition_controller_queue_latency|non_structural_schema_condition_controller_retries|non_structural_schema_condition_controller_unfinished_work_seconds|non_structural_schema_condition_controller_work_duration|rest_client_request_latency_seconds|storage_operation_errors_total|storage_operation_status_count)",
								SourceLabels: []monitoringv1.LabelName{"__name__"},
							},
						}, common.DropMetricsRelabeling(ctx)...),
					},
					{
						BearerTokenFile: "/var/run/secrets/kubernetes.io/serviceaccount/token",
						HonorLabels:     true,
						HonorTimestamps: common.ToPointer(false),
						Interval:        "60s",
						Path:            "/metrics/cadvisor",
						Port:            "https-metrics",
						Scheme:          "https",
						TLSConfig: &monitoringv1.TLSConfig{
							SafeTLSConfig: monitoringv1.SafeTLSConfig{
								InsecureSkipVerify: true,
							},
						},
						RelabelConfigs: []*monitoringv1.RelabelConfig{
							{
								SourceLabels: []monitoringv1.LabelName{"__metrics_path__"},
								TargetLabel:  "metrics_path",
							},
						},
						MetricRelabelConfigs: append([]*monitoringv1.RelabelConfig{
							{
								Action:       "drop",
								Regex:        "container_(network_tcp_usage_total|network_udp_usage_total|tasks_state|cpu_load_average_10s)",
								SourceLabels: []monitoringv1.LabelName{"__name__"},
							},
							{
								Action:       "drop",
								Regex:        "(container_spec_.*|container_file_descriptors|container_sockets|container_threads_max|container_threads|container_start_time_seconds|container_last_seen);;",
								SourceLabels: []monitoringv1.LabelName{"__name__", "pod", "namespace"},
							},
							{
								Action:       "drop",
								Regex:        "(container_blkio_device_usage_total);.+",
								SourceLabels: []monitoringv1.LabelName{"__name__", "container"},
							},
							{
								Action:       "drop",
								Regex:        "container_(memory_failures_total|fs_reads_total|cpu_user_seconds_total|memory_failcnt|cpu_system_seconds_total|memory_max_usage_bytes|memory_swap|processes|memory_cache|memory_mapped_file|memory_usage_bytes|sockets|spec_cpu_period|spec_memory_limit_bytes|file_descriptors|spec_memory_reservation_limit_bytes|last_seen|spec_cpu_shares|spec_memory_swap_limit_bytes|threads_max|start_time_seconds|threads|ulimits_soft|cpu_cfs_periods_total|cpu_cfs_throttled_periods_total|spec_cpu_quota|blkio_device_usage_total)",
								SourceLabels: []monitoringv1.LabelName{"__name__"},
							},
						}, common.DropMetricsRelabeling(ctx)...),
					},
					{
						BearerTokenFile: "/var/run/secrets/kubernetes.io/serviceaccount/token",
						HonorLabels:     true,
						Interval:        "60s",
						Port:            "https-metrics",
						Path:            "/metrics/probes",
						Scheme:          "https",
						RelabelConfigs: []*monitoringv1.RelabelConfig{
							{
								SourceLabels: []monitoringv1.LabelName{"__metrics_path__"},
								TargetLabel:  "metrics_path",
							},
						},
						MetricRelabelConfigs: common.DropMetricsRelabeling(ctx),
						TLSConfig: &monitoringv1.TLSConfig{
							SafeTLSConfig: monitoringv1.SafeTLSConfig{
								InsecureSkipVerify: true,
							},
						},
					},
				},
			},
		},
	}, nil
}
