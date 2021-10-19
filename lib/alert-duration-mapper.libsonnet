local alertDurationMap = {
  NodeFilesystemAlmostOutOfSpace: '15m',
};

{
  spec+: {
    groups: std.map(
      function(group) group {
        rules: std.map(
          function(rule)
            if 'alert' in rule && (rule.alert in alertDurationMap) then
              rule { 'for': alertDurationMap[rule.alert] }
            else
              rule,
          super.rules
        ),
      },
      super.groups
    ),
  },
}
