# Configuring GitLab Runner for AlloyCI

Below you can find some specific documentation on configuring GitLab Runner, the
shells supported, the security implications using the various executors, as
well as information how to set up Prometheus metrics:

- [Advanced configuration options](advanced-configuration.md) Learn how to use the [TOML][] configuration file that GitLab Runner uses.
- [Use self-signed certificates](tls-self-signed.md) Configure certificates that are used to verify TLS peer when connecting to the GitLab server.
- [Auto-scaling using Docker machine](autoscale.md) Execute jobs on machines that are created on demand using Docker machine.
- [Supported shells](../shells/README.md) Learn what shell script generators are supported that allow to execute builds on different systems.
- [Security considerations](../security/index.md) Be aware of potential security implications when running your jobs with GitLab Runner.
- [Cleanup the Docker images automatically](https://gitlab.com/gitlab-org/gitlab-runner-docker-cleanup) A simple Docker application that automatically garbage collects the GitLab Runner caches and images when running low on disk space.

[TOML]: https://github.com/toml-lang/toml
