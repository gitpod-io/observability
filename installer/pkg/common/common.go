package common

import (
	"k8s.io/apimachinery/pkg/runtime"
)

func MergeLists(runtimeObjectLists ...[]runtime.Object) []runtime.Object {
	var retObjects []runtime.Object
	for _, r := range runtimeObjectLists {
		retObjects = append(retObjects, r...)
	}
	return retObjects
}

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
