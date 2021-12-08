// This file is only used to load default values and make some top-level assertions.

local defaults = {
  namespace: 'monitoring-satellite'
};

function(config) defaults + config {
  assert std.objectHas(config, 'clusterName') : 'please provide clusterName',

}
