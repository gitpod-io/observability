package shared

import (
	corev1 "k8s.io/api/core/v1"
	policyv1beta1 "k8s.io/api/policy/v1beta1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/utils/pointer"
)

func restrictedPodsecurityPolicy() []runtime.Object {
	return []runtime.Object{
		&policyv1beta1.PodSecurityPolicy{
			TypeMeta: metav1.TypeMeta{
				APIVersion: "policy/v1beta1",
				Kind:       "PodSecurityPolicy",
			},
			ObjectMeta: metav1.ObjectMeta{
				Name: RestrictedPodsecurityPolicyName(),
			},
			Spec: policyv1beta1.PodSecurityPolicySpec{
				AllowPrivilegeEscalation: pointer.Bool(false),
				FSGroup: policyv1beta1.FSGroupStrategyOptions{
					Rule: policyv1beta1.FSGroupStrategyMustRunAs,
					Ranges: []policyv1beta1.IDRange{
						{Min: 1, Max: 65535},
					},
				},
				HostIPC:                  false,
				HostNetwork:              false,
				HostPID:                  false,
				Privileged:               false,
				ReadOnlyRootFilesystem:   false,
				RequiredDropCapabilities: []corev1.Capability{"ALL"},
				RunAsUser: policyv1beta1.RunAsUserStrategyOptions{
					Rule: policyv1beta1.RunAsUserStrategyMustRunAsNonRoot,
				},
				SELinux: policyv1beta1.SELinuxStrategyOptions{
					Rule: policyv1beta1.SELinuxStrategyRunAsAny,
				},
				SupplementalGroups: policyv1beta1.SupplementalGroupsStrategyOptions{
					Rule: policyv1beta1.SupplementalGroupsStrategyMustRunAs,
					Ranges: []policyv1beta1.IDRange{
						{Min: 1, Max: 65535},
					},
				},
				Volumes: []policyv1beta1.FSType{
					"configMap",
					"emptyDir",
					"secret",
					"projected",
					"persistentVolumeClaim",
				},
			},
		},
	}
}

func RestrictedPodsecurityPolicyName() string {
	return "restricted-psp"
}
