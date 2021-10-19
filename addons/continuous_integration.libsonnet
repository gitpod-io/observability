// Specific modification when running the stack on CI
{
  values+:: {
    prometheus+: {
      // Github Actions compute isn't strong, strip limits so pods can come up
      resources: {},
    },

    alertmanager+: {
      // Github Actions compute isn't strong, strip limits so pods can come up
      resources: {},
    },
  },
}
