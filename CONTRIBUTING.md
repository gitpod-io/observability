## Getting started

* Fork the repository on GitHub
* Read the [README](README.md) for the simplest YAML generation examples
* Play with the project, submit bug fixes, submit patches!

## Contribution Flow

This is a rough outline of what a contributor's workflow looks like:

* Create a new branch from where you want to base your work (usually main).
* Make commits of logical units.
* Make sure your commit messages are in the proper format (see [Commit message formatting](#commit-message-formatting)).
* Push your changes to a topic branch in your fork of the repository.
* Make sure the tests pass, and add any new tests as appropriate (see [Running tests](#running-tests)).
* Submit a pull request to the original repository.

Thanks for your contributions!

### Adding new external variables

This project relies heavily on external variables to provide a way of customizing both Monitoring-satellite and Monitoring-central. The trade-off for this decision is that jsonnet requires us to pass external variables through the command line when, otherwise it will fail during runtime.

Therefore, adding new external variables to the project is considered a breaking change and it requires modifications on extra parts of the repository:
* [hack/generate.sh](hack/generate.sh) needs to be updated with all new external variables introduced.
* [README](README.md) needs to be updated with all new external variables introduced. Including if they are required by default or if only behind a certain condition and a description of what they do.

### Adding new components

In an ideal world, new components that we'd like to add to any of our applications would already have a jsonnet library that we could easily import and use. Unfortunately, this is not a common practice. 

For the components that do not have a jsonnet library, we can create them ourselves under the [components](components/) directory. Those libraries should generate all manifests required to monitor this component, e.g. network policies, services and serviceMonitors. 

After adding a new library, make sure you're adding it to either [monitoring-satellite](monitoring-satellite/monitoring-satellite.libsonnet) or [monitoring-central](monitoring-central/monitoring-central.libsonnet).


### YAML generation

To make sure your changes have the effect you expect, it is useful to re-generate the manifests after your changes.

To generate all manifests run:

```
make generate
```

### Running tests

We have e2e tests to make sure our stack is running as expected. The tests run on every Pull Request by default, but you can also run them yourself.

A kubernetes cluster is required to run e2e tests, which means we can't run them from inside a Gitpod workspace :(

You can spin-up a kubernetes cluster and deploy monitoring-satellite by running the command:
```
make deploy-satellite
```

To run the tests, use the command:
```
make test-e2e
```

### Commit message formatting

We follow a rough convention for commit messages that is designed to answer two
questions: what changed and why. The subject line should feature the what and
the body of the commit should describe the why.

The format can be described more formally as follows:

```
<subsystem>: <what changed>
<BLANK LINE>
<why this change was made>
<BLANK LINE>
<footer>
```

The first line is the subject and should be no longer than 70 characters, the
second line is always blank, and other lines should be wrapped at 80 characters.
This allows the message to be easier to read on GitHub as well as in various
git tools.