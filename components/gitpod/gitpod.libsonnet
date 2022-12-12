function() {
  crossTeamsMixin:: (import 'gitpod/cross-teams/mixin.libsonnet'),

  ideMixin:: (import 'gitpod/IDE/mixin.libsonnet'),

  webappMixin:: (import 'gitpod/meta/mixin.libsonnet'),

  workspaceMixin:: (import 'gitpod/workspace/mixin.libsonnet'),

  selfhostedMixin:: (import 'gitpod/self-hosted/mixin.libsonnet'),

  platformMixin:: (import 'gitpod/platform/mixin.libsonnet'),

  mixin:: $.crossTeamsMixin + $.ideMixin + $.webappMixin + $.workspaceMixin + $.selfhostedMixin + $.platformMixin,
}
