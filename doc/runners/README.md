# Runners

In AlloyCI, Runners run your [JSON](../json/README.md) job configuration file.
A Runner is an isolated (virtual) machine that picks up jobs
through the coordinator API of AlloyCI.

A Runner can be specific to a certain project or serve any project
in AlloyCI. A Runner that serves all projects is called a Global Runner.

AlloyCI makes use of the GitLab CI Runner project, in order to take advantage
of a mature, feature-rich executor that has a straight forward interface for
communicating with the coordinator.

The GitLab Runner is written in [Go][golang] and can be run as a single binary,
no language specific requirements are needed.

It is designed to run on the GNU/Linux, macOS, and Windows operating systems.
Other operating systems will probably work as long as you can compile a Go
binary on them.

## Global vs. Specific Runners

A Runner that is specific only runs for the specified project. A global Runner
can run jobs for every project.

**Global Runners** are useful for jobs that have similar requirements,
between multiple projects. Rather than having multiple Runners idling for
many projects, you can have a single or a small number of Runners that handle
multiple projects. This makes it easier to maintain and update Runners.

**Specific Runners** are useful for jobs that have special requirements or for
projects with a specific demand. If a job has certain requirements, you can set
up the specific Runner with this in mind, while not having to do this for all
Runners. For example, if you want to deploy a certain project, you can setup
a specific Runner to have the right credentials for this.

Projects with high demand of CI activity can also benefit from using Specific Runners.
By having dedicated Runners you are guaranteed that the Runner is not being held
up by another project's jobs.

# Creating and Registering a Runner

There are several ways to create a Runner. Only after creation, upon
registration its status as Global or Specific is determined.

[See the documentation for](install/README.md)
the different methods of installing a Runner instance.

After installing the Runner, you can either register it as `Global` or as `Specific`.
You can only register a Global Runner if you have admin access to the AlloyCI
instance.

## Registering a Global Runner

Grab the Runner token on the `/admin/runners` page of your AlloyCI
instance.

Now simply register the Runner as any Runner:

```
sudo gitlab-runner register
```

##  Registering a Specific Runner with a Project Registration token

To create a specific Runner without having admin rights to the AlloyCI instance,
visit the project you want to make the Runner work for in AlloyCI.

Click on the `Edit` button and use the registration token you find there to
setup a specific Runner for this project.

To register the Runner, run the command below and follow instructions:

```
sudo gitlab-runner register
```

## Using Global Runners Effectively

If you are planning to use Global Runners, there are several things you
should keep in mind.

### Use Tags

You must setup a Runner to be able to run all the different types of jobs
that it may encounter on the projects it's shared over. This would be
problematic for large amounts of projects, if it wasn't for tags.

By tagging a Runner for the types of jobs it can handle, you can make sure
Global Runners will only run the jobs they are equipped to run.

For instance, for the AlloyCI project we use Runners tagged with `elixir`, and
make sure that they contain the dependencies to run Elixir, and Phoenix jobs.

### Runners with tags

Runners with tags will not be able to pick up build jobs that are untagged _unless_
they are registered with the `untagged` flag set to true.

### Be careful with sensitive information

If you can run a job on a Runner, you can get access to any code it runs
and get the token of the Runner. With shared Runners, this means that anyone
that runs jobs on the Runner, can access anyone else's code that runs on the Runner.

In addition, because you can get access to the Runner token, it is possible
to create a clone of a Runner and submit false jobs, for example.

The above is easily avoided by restricting the usage of shared Runners
on large public GitLab instances and controlling access to your GitLab instance.

## Attack vectors in Runners

Mentioned briefly earlier, but the following things of Runners can be exploited.
We're always looking for contributions that can mitigate these
[Security Considerations](security/README.md).

## Requirements

If you want to use Docker make sure that you have version `v1.5.0` at least
installed.

## Features

- Allows to run:
 - multiple jobs concurrently
 - use multiple tokens with multiple server (even per-project)
 - limit number of concurrent jobs per-token
- Jobs can be run:
 - locally
 - using Docker containers
 - using Docker containers and executing job over SSH
 - using Docker containers with autoscaling on different clouds and virtualization hypervisors
 - connecting to remote SSH server
- Is written in Go and distributed as single binary without any other requirements
- Supports Bash, Windows Batch and Windows PowerShell
- Works on GNU/Linux, OS X and Windows (pretty much anywhere you can run Docker)
- Allows to customize the job running environment
- Automatic configuration reload without restart
- Easy to use setup with support for Docker, Docker-SSH, Parallels or SSH running environments
- Enables caching of Docker containers
- Easy installation as a service for GNU/Linux, OSX and Windows
- Embedded Prometheus metrics HTTP server

## [Install GitLab Runner](install/README.md)

GitLab Runner can be installed and used on GNU/Linux, macOS, FreeBSD and Windows.
You can install it Using Docker, download the binary manually or use the
repository for rpm/deb packages that GitLab offers. Below you can find
information on the different installation methods:

- [Install using GitLab's repository for Debian/Ubuntu/CentOS/RedHat (preferred)](install/linux-repository.md)
- [Install on GNU/Linux manually (advanced)](install/linux-manually.md)
- [Install on macOS (preferred)](install/osx.md)
- [Install on Windows (preferred)](install/windows.md)
- [Install as a Docker Service](install/docker.md)
- [Install in Auto-scaling mode using Docker machine](install/autoscaling.md)
- [Install on FreeBSD](install/freebsd.md)
- [Install on Kubernetes](install/kubernetes.md)
- [Install the nightly binary manually (development)](install/bleeding-edge.md)

## [Register GitLab Runner](register/README.md)

Once GitLab Runner is installed, you need to register it with GitLab.

Learn how to [register a GitLab Runner](register/README.md).

## Using the Runner

- [See the commands documentation](commands/README.md)

## [Selecting the executor](executors/README.md)

GitLab Runner implements a number of executors that can be used to run your
builds in different scenarios. If you are not sure what to select, read the
[I'm not sure](executors/README.md#imnotsure) section.
Visit the [compatibility chart](executors/README.md#compatibility-chart) to find
out what features each executor supports and what not.

To jump into the specific documentation of each executor, visit:

- [Shell](executors/shell.md)
- [Docker](executors/docker.md)
- [Docker Machine and Docker Machine SSH (auto-scaling)](install/autoscaling.md)
- [Parallels](executors/parallels.md)
- [VirtualBox](executors/virtualbox.md)
- [SSH](executors/ssh.md)
- [Kubernetes](executors/kubernetes.md)

## [Advanced Configuration](configuration/README.md)

- [Advanced configuration options](configuration/advanced-configuration.md) Learn how to use the [TOML][] configuration file that GitLab Runner uses.
- [Use self-signed certificates](configuration/tls-self-signed.md) Configure certificates that are used to verify TLS peer when connecting to the GitLab server.
- [Auto-scaling using Docker machine](configuration/autoscale.md) Execute jobs on machines that are created on demand using Docker machine.
- [Supported shells](shells/README.md) Learn what shell script generators are supported that allow to execute builds on different systems.
- [Security considerations](security/README.md) Be aware of potential security implications when running your jobs with GitLab Runner.
- [Runner monitoring](monitoring/README.md) Learn how to monitor Runner's behavior.
- [Cleanup the Docker images automatically](https://gitlab.com/gitlab-org/gitlab-runner-docker-cleanup) A simple Docker application that automatically garbage collects the GitLab Runner caches and images when running low on disk space.

## Troubleshooting

Read the [FAQ](faq/README.md) for troubleshooting common issues.

## Copyright

Copyright (c) 2011-2017 GitLab B.V.

[golang]: https://golang.org/
[TOML]: https://github.com/toml-lang/toml
