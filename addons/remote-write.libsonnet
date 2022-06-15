function(config) {

  assert std.objectHas(config.remoteWrite, 'username') && std.objectHas(config.remoteWrite, 'password') : (
    "If 'remoteWrite' is set, 'username' and 'password' should be declared"
  ),
  assert std.objectHas(config.remoteWrite, 'urls') : (
    "If 'remoteWrite' is set, 'urls' should be declared"
  ),

  assert std.isArray(config.remoteWrite.urls) : (
    'remote-write URLs should be an array'
  ),

  prometheus+: {
    prometheus+: {
      spec+: {
        remoteWrite+: [
          {
            url: url,
            writeRelabelConfigs: (
              if std.objectHas(config.remoteWrite, 'writeRelabelConfigs') then
                assert std.isArray(config.remoteWrite.writeRelabelConfigs) : ('Remote write relabeling configs should be an array.');

                config.remoteWrite.writeRelabelConfigs
              else []
            ),
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
