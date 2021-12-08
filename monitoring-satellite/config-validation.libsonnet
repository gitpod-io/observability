// This is used only as a validation layer over the configuration scheme of monitoring-satellite


function(config) config {

  assert std.objectHas(config, 'clusterName') : 'please provide clusterName',
  assert std.objectHas(config, 'namespace') : 'please provide namespace',

  // Beware that jsonnet is not an imperative language, don't expect those if lines
  // to get evaluated as if were part of a script. Think of assertions as a "virtual"/invisible field
  // that must always evaluate to 'true'.

  // For those more advanced assertions, we're first making sure the top-level object doesn't exist.
  // If it exists, then the second part of the assertions are executed('A||B' construct), making assertions
  // more specific for each object.

  /*********** Alerting assertions ************/
  assert !std.objectHas(config, 'alerting') || (
    std.objectHas(config.alerting, 'slackWebhookURLWarning') &&
    std.objectHas(config.alerting, 'slackWebhookURLInfo') &&
    std.objectHas(config.alerting, 'slackChannelPrefix')
  ) : "If 'alerting' is set, 'slackWebhookURLWarning', 'slackWebhookURLInfo' and 'slackChannelPrefix' should be declared",

  assert !std.objectHas(config, 'alerting') || (
    std.objectHas(config.alerting, 'slackWebhookURLCritical') ||
    std.objectHas(config.alerting, 'pagerdutyRoutingKey')
  ) : "If 'alerting' is set, 'slackWebhookURLCritical' or 'pagerdutyRoutingKey' should be declared",


  /*********** Remote-write assertions ************/
  assert !std.objectHas(config, 'remoteWrite') || (
    std.objectHas(config.remoteWrite, 'username') ||
    std.objectHas(config.remoteWrite, 'password')
  ) : "If 'remoteWrite' is set, 'username' or 'password' should be declared",

  assert !std.objectHas(config, 'remoteWrite') || (
    std.objectHas(config.remoteWrite, 'urls') &&
    std.isArray(config.remoteWrite.urls)
  ) : "If 'remoteWrite' is set, 'urls' should be declared and be an array",


  /*********** Preview environment assertions ************/
  assert !std.objectHas(config, 'previewEnvironment') || (
    std.objectHas(config.previewEnvironment, 'prometheusDNS') &&
    std.objectHas(config.previewEnvironment, 'grafanaDNS')
  ) : "If 'previewEnvironment' is set, 'prometheusDNS' and 'grafanaDNS' should be declared",

  assert !std.objectHas(config, 'previewEnvironment') || (
    std.objectHas(config.previewEnvironment, 'nodeExporterPort') &&
    std.isNumber(config.previewEnvironment.nodeExporterPort)
  ) : "If 'previewEnvironment' is set, 'nodeExporterPort' should be declared and it should be a number",

}
