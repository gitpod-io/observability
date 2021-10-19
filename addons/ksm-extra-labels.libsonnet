{
  kubeStateMetrics+: {
    deployment+: {
      spec+: {
        template+: {
          spec+: {
            containers: std.map(
              function(c) c {
                args+:
                  if c.name == 'kube-state-metrics' then
                    ['--metric-labels-allowlist=nodes=[cloud.google.com/gke-nodepool,topology.kubernetes.io/region],pods=[component,workspaceType,owner,metaID]']
                  else
                    [],
              },
              super.containers
            ),
          },
        },
      },
    },
  },
}
