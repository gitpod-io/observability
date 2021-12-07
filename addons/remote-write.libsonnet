local config = std.extVar('config');

{
  prometheus+: {
    prometheus+: {
      spec+: {
        remoteWrite+: [
          {
            url: url,
            basicAuth: {
              username: {
                name: 'remote-write-auth',
                key: 'username',
              },
              password: {
                name: 'remote-write-auth',
                key: 'password',
              },
            },
          }
          for url in config.remoteWrite.urls
        ],
      },
    },

    remoteWriteAuthSecrets: {
      apiVersion: 'v1',
      kind: 'Secret',
      metadata: {
        name: 'remote-write-auth',
        labels: $.prometheus.prometheus.metadata.labels,
        namespace: $.prometheus.prometheus.metadata.namespace,
      },
      type: 'Opaque',
      data: {
        username: std.base64(config.remoteWrite.username),
        password: std.base64(config.remoteWrite.password),
      },
    },
  },
}
