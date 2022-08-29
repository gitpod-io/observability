package common

import (
	"regexp"
	"sort"
	"strings"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"sigs.k8s.io/yaml"
)

// Those occurring earlier in the list get installed before those occurring later in the list.
// Based on Helm's list, with our CRDs added in

var sortOrder = []string{
	"Namespace",
	"NetworkPolicy",
	"ResourceQuota",
	"Issuer",
	"Certificate",
	"LimitRange",
	"PodSecurityPolicy",
	"PodDisruptionBudget",
	"ServiceAccount",
	"Secret",
	"SecretList",
	"ConfigMap",
	"StorageClass",
	"PersistentVolume",
	"PersistentVolumeClaim",
	"CustomResourceDefinition",
	"ClusterRole",
	"ClusterRoleList",
	"ClusterRoleBinding",
	"ClusterRoleBindingList",
	"Role",
	"RoleList",
	"RoleBinding",
	"RoleBindingList",
	"Service",
	"DaemonSet",
	"Pod",
	"ReplicationController",
	"ReplicaSet",
	"StatefulSet",
	"Deployment",
	"HorizontalPodAutoscaler",
	"Job",
	"CronJob",
	"Ingress",
	"APIService",
	"Prometheus",
	"Alertmanager",
	"ServiceMonitor",
	"PodMonitor",
	"PrometheusRule",
}

type RuntimeObject struct {
	metav1.TypeMeta `json:",inline"`
	Metadata        metav1.ObjectMeta `json:"metadata"`
	Content         string            `json:"-"`
}

func DependencySortingRenderFunc(objects []RuntimeObject) ([]RuntimeObject, error) {
	sortMap := map[string]int{}
	for k, v := range sortOrder {
		sortMap[v] = k
	}

	sort.SliceStable(objects, func(i, j int) bool {
		scoreI := sortMap[objects[i].Kind]
		scoreJ := sortMap[objects[j].Kind]

		if scoreI == scoreJ {
			return objects[i].Metadata.Name < objects[j].Metadata.Name
		}

		return scoreI < scoreJ
	})

	return objects, nil
}

func YamlToRuntimeObject(objects []string) ([]RuntimeObject, error) {
	sortedObjects := make([]RuntimeObject, 0, len(objects))
	for _, o := range objects {
		// Assume multi-document YAML
		re := regexp.MustCompile("(^|\n)---")
		items := re.Split(o, -1)

		for _, p := range items {
			var v RuntimeObject
			err := yaml.Unmarshal([]byte(p), &v)
			if err != nil {
				return nil, err
			}

			// remove any empty charts
			ctnt := strings.Trim(p, "\n")
			if len(strings.TrimSpace(ctnt)) == 0 {
				continue
			}

			v.Content = ctnt
			sortedObjects = append(sortedObjects, v)
		}
	}

	return sortedObjects, nil
}
