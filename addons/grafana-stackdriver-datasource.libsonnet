local privateKey = '|\n' + std.extVar('stackdriver_private_key');

{
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
            clientEmail: std.extVar('stackdriver_client_email'),
            defaultProject: std.extVar('stackdriver_default_project'),
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
