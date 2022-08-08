package common

import (
	appsv1 "k8s.io/api/apps/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/util/intstr"
)

var (
	DeploymentType = metav1.TypeMeta{
		APIVersion: "apps/v1",
		Kind:       "Deployment",
	}
	ServiceType = metav1.TypeMeta{
		APIVersion: "apps/v1",
		Kind:       "Service",
	}
)

func DeploymentStrategy(maxSurge, maxUnavailability int32) appsv1.DeploymentStrategy {
	return appsv1.DeploymentStrategy{
		Type: appsv1.RollingUpdateDeploymentStrategyType,
		RollingUpdate: &appsv1.RollingUpdateDeployment{
			MaxSurge:       &intstr.IntOrString{IntVal: maxSurge},
			MaxUnavailable: &intstr.IntOrString{IntVal: maxUnavailability},
		},
	}
}
