# The Kubernetes executor

GitLab Runner can use Kubernetes to run builds on a kubernetes cluster. This is
possible with the use of the **Kubernetes** executor.

The **Kubernetes** executor, when used with GitLab CI, connects to the Kubernetes
API in the cluster creating a Pod for each GitLab CI Job. This Pod is made
up of, at the very least, a build container and an additional container for each
`service` defined by the GitLab CI yaml. The names for these containers
are as follows:

- The build container is `build`
- The services containers are `svc-X` where `X` is `[0-9]+`

## Workflow

The Kubernetes executor divides the build into multiple steps:

1. **Prepare**: Create the Pod against the Kubernetes Cluster.
	This creates the containers required for the build and services to run.
1. **Pre-build**: Clone, restore cache and download artifacts from previous
   stages. This is run on a special container as part of the Pod.
1. **Build**: User build.
1. **Post-build**: Create cache, upload artifacts to GitLab. This also uses
   the special container as part of the Pod.

## Connecting to the Kubernetes API

The following options are provided, which allow you to connect to the Kubernetes API:

- `host`: Optional Kubernetes apiserver host URL (auto-discovery attempted if not specified)
- `cert_file`: Optional Kubernetes apiserver user auth certificate
- `key_file`: Optional Kubernetes apiserver user auth private key
- `ca_file`: Optional Kubernetes apiserver ca certificate

The user account provided must have permission to create, list and attach to Pods in
the specified namespace in order to function.

If you are running the GitLab CI Runner within the Kubernetes cluster you can omit
all of the above fields to have the Runner auto-discovery the Kubernetes API. This
is the recommended approach.

If you are running it externally to the Cluster then you will need to set each
of these keywords and make sure that the Runner has access to the Kubernetes API
on the cluster.

## The keywords

The following keywords help to define the behaviour of the Runner within Kubernetes:

- `namespace`: Namespace to run Kubernetes Pods in
- `namespace_overwrite_allowed`: Regular expression to validate the contents of
  the namespace overwrite environment variable (documented following). When empty,
  it disables the namespace overwrite feature
- `privileged`: Run containers with the privileged flag
- `cpu_limit`: The CPU allocation given to build containers
- `memory_limit`: The amount of memory allocated to build containers
- `service_cpu_limit`: The CPU allocation given to build service containers
- `service_memory_limit`: The amount of memory allocated to build service containers
- `helper_cpu_limit`: The CPU allocation given to build helper containers
- `helper_memory_limit`: The amount of memory allocated to build helper containers
- `cpu_request`: The CPU allocation requested for build containers
- `memory_request`: The amount of memory requested from build containers
- `service_cpu_request`: The CPU allocation requested for build service containers
- `service_memory_request`: The amount of memory requested for build service containers
- `helper_cpu_request`: The CPU allocation requested for build helper containers
- `helper_memory_request`: The amount of memory requested for build helper containers
- `pull_policy`: specify the image pull policy: `never`, `if-not-present`, `always`. The cluster default will be used if not set.
- `node_selector`: A `table` of `key=value` pairs of `string=string`. Setting this limits the creation of pods to kubernetes nodes matching all the `key=value` pairs
- `image_pull_secrets`: A array of secrets that are used to authenticate docker image pulling
- `helper_image`: [ADVANCED] Override the default helper image used to clone repos and upload artifacts
- `terminationGracePeriodSeconds`: Duration after the processes running in the pod are sent a termination signal and the time when the processes are forcibly halted with a kill signal
- `poll_interval`: How frequently, in seconds, the runner will poll the Kubernetes pod it has just created to check its status. [Default: 3]
- `poll_timeout`: The amount of time, in seconds, that needs to pass before the runner will timeout attempting to connect to the container it has just created (useful for queueing more builds that the cluster can handle at a time) [Default: 180]
- `pod_labels`: A set of labels to be added to each build pod created by the runner. The value of these can include environment variables for expansion.
- `service-account`: default service account to be used for making kubernetes api calls.
- `service_account_overwrite_allowed`: Regular expression to validate the contents of
  the service account overwrite environment variable. When empty,
    it disables the service account overwrite feature

### Configuring executor Service Account

You can set the `KUBERNETES_SERVICE_ACCOUNT` environment variable or use `--service-account` flag

### Overwriting Kubernetes Namespace

Additionally, Kubernetes namespace can be overwritten on `.gitlab-ci.yml` file, by using the variable
`KUBERNETES_NAMESPACE_OVERWRITE`.

This approach allow you to create a new isolated namespace dedicated for CI purposes, and deploy a custom
set of Pods. The `Pods` spawned by the runner will take place on the overwritten namespace, for simple
and straight forward access between container during the CI stages.

``` yaml
variables:
  KUBERNETES_NAMESPACE_OVERWRITE: ci-${CI_COMMIT_REF_NAME}
```

Furthermore, to ensure only designated namespaces will be used during CI runs, inform the configuration
`namespace_overwrite_allowed` with proper regular expression. When left empty the overwrite behaviour is
disabled.

### Overwriting Kubernetes Default Service Account

Additionally, Kubernetes service account can be overwritten on `.gitlab-ci.yml` file, by using the variable
`KUBERNETES_SERVICE_ACCOUNT_OVERWRITE`.

This approach allow you to specify a service account that is attached to the namespace, usefull when dealing
with complex RBAC configurations.
``` yaml
variables:
  KUBERNETES_SERVICE_ACCOUNT_OVERWRITE: ci-service-account
```
usefull when overwritting the namespace and RBAC is setup in the cluster.

To ensure only designated service accounts will be used during CI runs, inform the configuration
 `service_account_overwrite_allowed` or set the environment variable `KUBERNETES_SERVICE_ACCOUNT_OVERWRITE_ALLOWED`
 with proper regular expression. When left empty the overwrite behaviour is disabled.

## Define keywords in the config toml

Each of the keywords can be defined in the `config.toml` for the gitlab runner.

Here is an example `config.toml`:

```toml
concurrent = 4

[[runners]]
  name = "Kubernetes Runner"
  url = "https://gitlab.com/ci"
  token = "......"
  executor = "kubernetes"
  [runners.kubernetes]
    host = "https://45.67.34.123:4892"
    cert_file = "/etc/ssl/kubernetes/api.crt"
    key_file = "/etc/ssl/kubernetes/api.key"
    ca_file = "/etc/ssl/kubernetes/ca.crt"
    namespace = "gitlab"
    namespace_overwrite_allowed = "ci-.*"
    privileged = true
    cpu_limit = "1"
    memory_limit = "1Gi"
    service_cpu_limit = "1"
    service_memory_limit = "1Gi"
    helper_cpu_limit = "500m"
    helper_memory_limit = "100Mi"
    poll_interval = 5
    poll_timeout = 3600
    [runners.kubernetes.node_selector]
      gitlab = "true"
```

## Using Docker in your builds

There are a couple of caveats when using docker in your builds while running on
a kubernetes cluster. Most of these issues are already discussed in the
[**Using Docker Build**](https://docs.gitlab.com/ce/ci/docker/using_docker_build.html)
section of the gitlab-ci
documentation but it is worth it to revisit them here as you might run into
some slightly different things when running this on your cluster.

### Exposing `/var/run/docker.sock`
Exposing your host's `/var/run/docker.sock` into your build container brings the
same risks with it as always. That node's containers are accessible from the
build container and depending if you are running builds in the same cluster as
your production containers it might not be wise to do that.

> **Note**:
Pods are not yet able to be scheduled to nodes with certain labels like
`role=build` using the `nodeSelector` field in the `PodSpec`, the only separation
between build Pods and the rest of the system is by namespace.

### Using `docker:dind`
Running the `docker:dind` also known as the `docker-in-docker` image is also
possible but sadly needs the containers to be run in privileged mode.
If you're willing to take that risk other problems will arise that might not
seem as straight forward at first glance. Because the docker daemon is started
as a `service` usually in your `.gitlab-ci.yaml` it will be run as a separate
container in your Pod. Basically containers in Pods only share volumes assigned
to them and an IP address by which they can reach each other using `localhost`.
`/var/run/docker.sock` is not shared by the `docker:dind` container and the `docker`
binary tries to use it by default. To overwrite this and make the client use tcp
to contact the docker daemon in the other container be sure to include
`DOCKER_HOST=tcp://localhost:2375` in your environment variables of the build container.

### Not supplying git
Do *not* try to use an image that doesn't supply git and add the `GIT_STRATEGY=none`
environment variable for a job that you think doesn't need to do a fetch or clone.
Because Pods are ephemeral and do not keep state of previously run jobs your
checked out code will not exist in both the build and the docker service container.
Error's you might run into are things like `could not find git binary` and
the docker service complaining that it cannot follow some symlinks into your
build context because of the missing code.

### Resource separation
In both the `docker:dind` and `/var/run/docker.sock` cases the docker daemon
has access to the underlying kernel of the host machine. This means that any
`limits` that had been set in the Pod will not work when building docker images.
The docker daemon will report the full capacity of the node regardless of
the limits imposed on the docker build containers spawned by kubernetes.
