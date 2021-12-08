// This is used only as a validation layer over the configuration scheme of monitoring-satellite


function(config) config {

  assert std.objectHas(config, 'clusterName') : 'please provide clusterName',
  assert std.objectHas(config, 'namespace') : 'please provide namespace',

}
