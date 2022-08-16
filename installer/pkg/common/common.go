package common

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

func Labels(name, component, app, version string) map[string]string {
	return map[string]string{
		"app.kubernetes.io/component": component,
		"app.kubernetes.io/name":      name,
		"app.kubernetes.io/part-of":   app,
		"app.kubernetes.io/version":   version,
	}
}

func ToPointer[T any](o T) *T {
	return &o
}

// TODO(cw): find a better way to do this. Those values must exist in the appropriate places already.
var (
	TypeMetaConfigmap = metav1.TypeMeta{
		APIVersion: "v1",
		Kind:       "ConfigMap",
	}
	TypeMetaBatchJob = metav1.TypeMeta{
		APIVersion: "batch/v1",
		Kind:       "Job",
	}
	TypeMetaNetworkPolicy = metav1.TypeMeta{
		APIVersion: "networking.k8s.io/v1",
		Kind:       "NetworkPolicy",
	}
)
