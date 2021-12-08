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
