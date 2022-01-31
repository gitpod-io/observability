function(config) {

  assert std.objectHas(config.stackdriver, 'privateKey') : (
    "If 'stackdriver' is set, 'privateKey' should be declared"
  ),

  assert std.objectHas(config.stackdriver, 'clientEmail') : (
    "If 'stackdriver' is set, 'clientEmail' should be declared"
  ),

  assert std.objectHas(config.stackdriver, 'defaultProject') : (
    "If 'stackdriver' is set, 'defaultProject' should be declared"
  ),

  local privateKey =
    |||
      %(privateKey)s
    ||| % config.stackdriver,

  values+:: {
    grafana+: {
      datasources+: [
        {
          name: 'Google Stackdriver',
          type: 'stackdriver',
          access: 'proxy',
          jsonData: {
            tokenUri: 'https://oauth2.googleapis.com/token',
            authenticationType: 'jwt',
            clientEmail: config.stackdriver.clientEmail,
            defaultProject: config.stackdriver.defaultProject,
          },
          secureJsonData: {
            privateKey: privateKey,
          },
          editable: false,
        },
      ],
    },
  },
}
