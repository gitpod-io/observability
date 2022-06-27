package e2e

import (
	"context"
	"log"
	"os"
	"testing"
	"time"

	"github.com/pkg/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/util/wait"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
)

var promClient *prometheusClient

func TestMain(m *testing.M) {
	os.Exit(testMain(m))
}

// testMain circumvents the issue, that one can not call `defer` in TestMain, as
// `os.Exit` does not honor `defer` statements. For more details see:
// http://blog.englund.nu/golang,/testing/2017/03/12/using-defer-in-testmain.html
func testMain(m *testing.M) int {
	kubeConfigPath, ok := os.LookupEnv("KUBECONFIG")
	if !ok {
		log.Fatal("failed to retrieve KUBECONFIG env var")
	}

	config, err := clientcmd.BuildConfigFromFlags("", kubeConfigPath)
	if err != nil {
		log.Fatal(err)
	}

	kubeClient, err := kubernetes.NewForConfig(config)
	if err != nil {
		log.Fatal(errors.Wrap(err, "creating kubeClient failed"))
	}

	promClient = newPrometheusClient(kubeClient)

	return m.Run()
}

// TestDeployments tests if all deployments of our stack can get to the ready state.
func TestDeployments(t *testing.T) {
	kClient := promClient.kubeClient

	apps := []string{"grafana", "kube-state-metrics", "prometheus-operator", "otel-collector", "kubescape", "blackbox-exporter"}

	for _, app := range apps {
		// Table-driven + parallel tests are quite tricky and require us
		// to re-capture the range variable.
		// Also read: https://eleni.blog/2019/05/11/parallel-test-execution-in-go/
		app := app
		t.Run(app, func(t *testing.T) {
			t.Parallel()
			err := wait.Poll(15*time.Second, 10*time.Minute, func() (bool, error) {
				deployment, err := kClient.AppsV1().Deployments("monitoring-satellite").Get(context.Background(), app, metav1.GetOptions{})
				if err != nil {
					t.Logf("%v deployment not ready", app)
					return false, nil
				}
				return deployment.Status.ReadyReplicas == *deployment.Spec.Replicas, nil
			})
			if err != nil {
				t.Fatal(errors.Wrapf(err, "Timeout while waiting for %v deployment ready condition.", app))
			}
		})
	}
}

// TestDaemonsets tests if all daemonsets of our stack can get to the ready state.
func TestDaemonsets(t *testing.T) {
	kClient := promClient.kubeClient

	apps := []string{"node-exporter"}

	for _, app := range apps {
		// Table-driven + parallel tests are quite tricky and require us
		// to re-capture the range variable.
		// Also read: https://eleni.blog/2019/05/11/parallel-test-execution-in-go/
		app := app
		t.Run(app, func(t *testing.T) {
			t.Parallel()
			err := wait.Poll(15*time.Second, 5*time.Minute, func() (bool, error) {
				daemonset, err := kClient.AppsV1().DaemonSets("monitoring-satellite").Get(context.Background(), app, metav1.GetOptions{})
				if err != nil {
					t.Logf("%v daemonset not ready", app)
					return false, nil
				}
				return daemonset.Status.NumberReady == daemonset.Status.DesiredNumberScheduled, nil
			})
			if err != nil {
				t.Fatal(errors.Wrapf(err, "Timeout while waiting for %v daemonset ready condition.", app))
			}
		})
	}
}

// TestStatefulsets tests if all statefulsets of our stack can get to the ready state.
func TestStatefulsets(t *testing.T) {
	kClient := promClient.kubeClient

	apps := []string{"alertmanager-main", "prometheus-k8s"}
	for _, app := range apps {
		// Table-driven + parallel tests are quite tricky and require us
		// to re-capture the range variable.
		// Also read: https://eleni.blog/2019/05/11/parallel-test-execution-in-go/
		app := app
		t.Run(app, func(t *testing.T) {
			t.Parallel()
			err := wait.Poll(15*time.Second, 5*time.Minute, func() (bool, error) {
				sts, err := kClient.AppsV1().StatefulSets("monitoring-satellite").Get(context.Background(), app, metav1.GetOptions{})
				if err != nil {
					return false, nil
				}
				return sts.Status.ReadyReplicas == *sts.Spec.Replicas, nil
			})
			if err != nil {
				t.Fatal(errors.Wrapf(err, "Timeout while waiting for %v statefulset ready condition.", app))
			}
		})
	}
}

func TestQueryPrometheus(t *testing.T) {
	queries := []struct {
		query   string
		expectN int
	}{
		{
			query:   `up{job="node-exporter"} == 1`,
			expectN: 1,
		}, {
			query:   `up{job="apiserver"} == 1`,
			expectN: 1,
		}, {
			query:   `up{job="kube-state-metrics"} == 1`,
			expectN: 2,
		}, {
			query:   `up{job="prometheus-k8s"} == 1`,
			expectN: 2,
		}, {
			query:   `up{job="prometheus-operator"} == 1`,
			expectN: 1,
		}, {
			query:   `up{job="alertmanager-main"} == 1`,
			expectN: 2,
		},{
			query:   `up{job="kubescape"} == 1`,
			expectN: 1,
		},
		// As we want to guarantee more targets, add more tests below
	}

	for _, q := range queries {
		// Table-driven + parallel tests are quite tricky and require us
		// to re-capture the range variable.
		// Also read: https://eleni.blog/2019/05/11/parallel-test-execution-in-go/
		q := q
		t.Run(q.query, func(t *testing.T) {
			t.Parallel()
			err := wait.Poll(5*time.Second, 1*time.Minute, func() (bool, error) {
				n, err := promClient.query(q.query)
				if err != nil {
					return false, err
				}
				if n != q.expectN {
					// Don't return an error as targets may only become visible after a while.
					t.Logf("expected %d result(s) for %q but got %d", q.expectN, q.query, n)
					return false, nil
				}
				t.Logf("query %q succeeded", q.query)
				return true, nil
			})
			if err != nil {
				t.Fatal(err)
			}
		})
	}
}
