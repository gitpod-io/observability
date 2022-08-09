package otelCollector

import (
	"github.com/gitpod-io/observability/installer/pkg/common"
	policyv1beta1 "k8s.io/api/policy/v1beta1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
)

func podsecuritypolicy() []runtime.Object {
	return []runtime.Object{
		&policyv1beta1.PodSecurityPolicy{
			TypeMeta: metav1.TypeMeta{
				APIVersion: "policy/v1beta1",
				Kind:       "PodSecurityPolicy",
			},
			ObjectMeta: metav1.ObjectMeta{
				Name:   Name,
				Labels: common.Labels(Name, Component, App, Version),
			},
			Spec: policyv1beta1.PodSecurityPolicySpec{
				FSGroup: policyv1beta1.FSGroupStrategyOptions{
					Rule: policyv1beta1.FSGroupStrategyRunAsAny,
				},
				Privileged: false,
				RunAsUser: policyv1beta1.RunAsUserStrategyOptions{
					Rule: policyv1beta1.RunAsUserStrategyRunAsAny,
				},
				SELinux: policyv1beta1.SELinuxStrategyOptions{
					Rule: policyv1beta1.SELinuxStrategyRunAsAny,
				},
				SupplementalGroups: policyv1beta1.SupplementalGroupsStrategyOptions{
					Rule: policyv1beta1.SupplementalGroupsStrategyRunAsAny,
				},
				Volumes: []policyv1beta1.FSType{"*"},
			},
		},
	}
}
