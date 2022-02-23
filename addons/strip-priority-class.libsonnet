{
  nodeExporter+: {
    daemonset+: {
      spec+: {
        template+: {
          spec+: {
            priorityClassName:: null,
          },
        },
      },
    },
  },
}
