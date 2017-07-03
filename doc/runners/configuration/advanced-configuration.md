# Advanced configuration

GitLab Runner configuration uses the [TOML][] format.

The file to be edited can be found in:

1. `/etc/gitlab-runner/config.toml` on \*nix systems when gitlab-runner is
   executed as root (**this is also path for service configuration**)
1. `~/.gitlab-runner/config.toml` on \*nix systems when gitlab-runner is
   executed as non-root
1. `./config.toml` on other systems

## The global section

This defines global settings of multi-runner.

| Setting | Description |
| ------- | ----------- |
| `concurrent`     | limits how many jobs globally can be run concurrently. The most upper limit of jobs using all defined runners. `0` **does not** mean unlimited |
| `log_level`      | Log level (options: debug, info, warn, error, fatal, panic). Note that this setting has lower priority than log-level set by command line argument --debug, -l or --log-level |
| `check_interval` | defines in seconds how often to check GitLab for a new builds |
| `sentry_dsn`     | enable tracking of all system level errors to sentry |
| `metrics_server` | address (`<host>:<port>`) on which the Prometheus metrics HTTP server should be listening |

Example:

```bash
concurrent = 4
log_level = "warning"
```

## The [[runners]] section

This defines one runner entry.

| Setting | Description |
| ------- | ----------- |
| `name`               | not used, just informatory |
| `url`                | CI URL |
| `token`              | runner token |
| `tls-ca-file`        | file containing the certificates to verify the peer when using HTTPS |
| `tls-cert-file`      | file containing the certificate to authenticate with the peer when using HTTPS |
| `tls-key-file`       | file containing the private key to authenticate with the peer when using HTTPS |
| `limit`              | limit how many jobs can be handled concurrently by this token. `0` (default) simply means don't limit |
| `executor`           | select how a project should be built, see next section |
| `shell`              | the name of shell to generate the script (default value is platform dependent) |
| `builds_dir`         | directory where builds will be stored in context of selected executor (Locally, Docker, SSH) |
| `cache_dir`          | directory where build caches will be stored in context of selected executor (Locally, Docker, SSH). If the `docker` executor is used, this directory needs to be included in its `volumes` parameter. |
| `environment`        | append or overwrite environment variables |
| `disable_verbose`    | don't print run commands |
| `request_concurrency` | limit number of concurrent requests for new jobs from GitLab (default 1) |
| `output_limit`       | set maximum build log size in kilobytes, by default set to 4096 (4MB) |
| `pre_clone_script`   | commands to be executed on the runner before cloning the Git repository. this can be used to adjust the Git client configuration first, for example. To insert multiple commands, use a (triple-quoted) multi-line string or "\n" character. |
| `pre_build_script`   | commands to be executed on the runner after cloning the Git repository, but before executing the build. To insert multiple commands, use a (triple-quoted) multi-line string or "\n" character. |
| `post_build_script`  | commands to be executed on the runner just after executing the build, but before executing `after_script`. To insert multiple commands, use a (triple-quoted) multi-line string or "\n" character. |

Example:

```bash
[[runners]]
  name = "ruby-2.1-docker"
  url = "https://CI/"
  token = "TOKEN"
  limit = 0
  executor = "docker"
  builds_dir = ""
  shell = ""
  environment = ["ENV=value", "LC_ALL=en_US.UTF-8"]
  disable_verbose = false
```

## The EXECUTORS

There are a couple of available executors currently.

| Executor | Description |
| -------- | ----------- |
| `shell`       | run build locally, default |
| `docker`      | run build using Docker container - this requires the presence of `[runners.docker]` and [Docker Engine][] installed on the system that the Runner runs |
| `docker-ssh`  | run build using Docker container, but connect to it with SSH - this requires the presence of `[runners.docker]` , `[runners.ssh]` and [Docker Engine][] installed on the system that the Runner runs. **Note: This will run the docker container on the local machine, it just changes how the commands are run inside that container. If you want to run docker commands on an external machine, then you should change the `host` parameter in the `runners.docker` section.**|
| `ssh`         | run build remotely with SSH - this requires the presence of `[runners.ssh]` |
| `parallels`   | run build using Parallels VM, but connect to it with SSH - this requires the presence of `[runners.parallels]` and `[runners.ssh]` |
| `virtualbox`  | run build using VirtualBox VM, but connect to it with SSH - this requires the presence of `[runners.virtualbox]` and `[runners.ssh]` |
| `docker+machine` | like `docker`, but uses [auto-scaled docker machines](autoscale.md) - this requires the presence of `[runners.docker]` and `[runners.machine]` |
| `docker-ssh+machine` | like `docker-ssh`, but uses [auto-scaled docker machines](autoscale.md) - this requires the presence of `[runners.docker]` and `[runners.machine]` |
| `kubernetes` | run build using Kubernetes Pods - this requires the presence of `[runners.kubernetes]` |

## The SHELLS

There are a couple of available shells that can be run on different platforms.

| Shell | Description |
| ----- | ----------- |
| `bash`        | generate Bash (Bourne-shell) script. All commands executed in Bash context (default for all Unix systems) |
| `sh`          | generate Sh (Bourne-shell) script. All commands executed in Sh context (fallback for `bash` for all Unix systems) |
| `cmd`         | generate Windows Batch script. All commands are executed in Batch context (default for Windows) |
| `powershell`  | generate Windows PowerShell script. All commands are executed in PowerShell context |

## The [runners.docker] section

This defines the Docker Container parameters.

| Parameter | Description |
| --------- | ----------- |
| `host`                      | specify custom Docker endpoint, by default `DOCKER_HOST` environment is used or `unix:///var/run/docker.sock` |
| `hostname`                  | specify custom hostname for Docker container |
| `tls_cert_path`             | when set it will use `ca.pem`, `cert.pem` and `key.pem` from that folder to make secure TLS connection to Docker (useful in boot2docker) |
| `image`                     | use this image to run builds |
| `cpuset_cpus`               | string value containing the cgroups CpusetCpus to use |
| `cpus`                      | number of CPUs (available in docker 1.13 or later) |
| `dns`                       | a list of DNS servers for the container to use |
| `dns_search`                | a list of DNS search domains |
| `privileged`                | make container run in Privileged mode (insecure) |
| `userns_mode`               | Sets the usernamespace mode for the container when usernamespace remapping option is enabled. (available in docker 1.10 or later) |
| `cap_add`                   | add additional Linux capabilities to the container |
| `cap_drop`                  | drop additional Linux capabilities from the container |
| `security_opt`              | set security options (--security-opt in docker run), takes a list of ':' separated key/values |
| `devices`                   | share additional host devices with the container |
| `disable_cache`             | disable automatic |
| `network_mode`              | add container to a custom network |
| `wait_for_services_timeout` | specify how long to wait for docker services, set to 0 to disable, default: 30 |
| `cache_dir`                 | specify where Docker caches should be stored (this can be absolute or relative to current working directory) |
| `volumes`                   | specify additional volumes that should be mounted (same syntax as Docker -v option) |
| `extra_hosts`               | specify hosts that should be defined in container environment |
| `shm_size`                  | specify shared memory size for images (in bytes) |
| `volumes_from`              | specify a list of volumes to inherit from another container in the form <code>\<container name\>[:\<ro&#124;rw\>]</code> |
| `volume_driver`             | specify the volume driver to use for the container |
| `links`                     | specify containers which should be linked with building container |
| `services`                  | specify additional services that should be run with build. Please visit [Docker Registry](https://registry.hub.docker.com/) for list of available applications. Each service will be run in separate container and linked to the build. |
| `allowed_images`            | specify wildcard list of images that can be specified in .gitlab-ci.yml. If not present all images are allowed (equivalent to `["*/*:*"]`) |
| `allowed_services`          | specify wildcard list of services that can be specified in .gitlab-ci.yml. If not present all images are allowed (equivalent to `["*/*:*"]`) |
| `pull_policy`               | specify the image pull policy: `never`, `if-not-present` or `always` (default); read more in the [pull policies documentation](../executors/docker.md#how-pull-policies-work) |

Example:

```bash
[runners.docker]
  host = ""
  hostname = ""
  tls_cert_path = "/Users/ayufan/.boot2docker/certs"
  image = "ruby:2.1"
  cpuset_cpus = "0,1"
  dns = ["8.8.8.8"]
  dns_search = [""]
  privileged = false
  userns_mode = "host"
  cap_add = ["NET_ADMIN"]
  cap_drop = ["DAC_OVERRIDE"]
  devices = ["/dev/net/tun"]
  disable_cache = false
  wait_for_services_timeout = 30
  cache_dir = ""
  volumes = ["/data", "/home/project/cache"]
  extra_hosts = ["other-host:127.0.0.1"]
  shm_size = 300000
  volumes_from = ["storage_container:ro"]
  links = ["mysql_container:mysql"]
  services = ["mysql", "redis:2.8", "postgres:9"]
  allowed_images = ["ruby:*", "python:*", "php:*"]
  allowed_services = ["postgres:9.4", "postgres:latest"]
```

### Volumes in the [runners.docker] section

You can find the complete guide of Docker volume usage
[here](https://docs.docker.com/userguide/dockervolumes/).

Let's use some examples to explain how it work (assuming you have a working
runner).

#### Example 1: adding a data volume

A data volume is a specially-designated directory within one or more containers
that bypasses the Union File System. Data volumes are designed to persist data,
independent of the container's life cycle.

```bash
[runners.docker]
  host = ""
  hostname = ""
  tls_cert_path = "/Users/ayufan/.boot2docker/certs"
  image = "ruby:2.1"
  privileged = false
  disable_cache = true
  volumes = ["/path/to/volume/in/container"]
```

This will create a new volume inside the container at `/path/to/volume/in/container`.

#### Example 2: mount a host directory as a data volume

In addition to creating a volume using you can also mount a directory from your
Docker daemon's host into a container. It's useful when you want to store
builds outside the container.

```bash
[runners.docker]
  host = ""
  hostname = ""
  tls_cert_path = "/Users/ayufan/.boot2docker/certs"
  image = "ruby:2.1"
  privileged = false
  disable_cache = true
  volumes = ["/path/to/bind/from/host:/path/to/bind/in/container:rw"]
```

This will use `/path/to/bind/from/host` of the CI host inside the container at
`/path/to/bind/in/container`.

### Using a private container registry

> **Notes:**
- This feature requires GitLab Runner **1.8** or higher
- For GitLab Runner versions **>= 0.6, <1.8** there was a partial
  support for using private registries, which required manual configuration
  of credentials on runner's host. We recommend to upgrade your Runner to
  at least version **1.8** if you want to use private registries.
- Using private registries with the `if-not-present` pull policy may introduce
  [security implications][secpull]. To fully understand how pull policies work,
  read the [pull policies documentation](../executors/docker.md#how-pull-policies-work).

If you want to use private registries as a source of images for your builds,
you can set the authorization configuration in the `DOCKER_AUTH_CONFIG`
[secret variable]. It can be set in both GitLab Variables section of
a project and in the `config.toml` file.

For a detailed example, visit the [Using Docker images documentation][priv-example].

The steps performed by the Runner can be summed up to:

1. The registry name is found from the image name.
1. If the value is not empty, the executor will search for the authentication
   configuration for this registry.
1. Finally, if an authentication corresponding to the specified registry is
   found, subsequent pulls will make use of it.

Now that the Runner is set up to authenticate against your private registry,
learn [how to configure .gitlab-ci.yml][yaml-priv-reg] in order to use that
registry.

#### Support for GitLab integrated registry

> **Note:**
To work automatically with private/protected images from
GitLab integrated registry it needs at least GitLab CE/EE **8.14**
and GitLab Runner **1.8**.

Starting with GitLab CE/EE 8.14, GitLab will send credentials for its integrated
registry along with the build data. These credentials will be automatically
added to registries authorization parameters list.

After this authorization against the registry will be proceed like for
configuration added with `DOCKER_AUTH_CONFIG` variable.

Thanks to this, in your builds you can use any image from you GitLab integrated
registry, even if the image is private/protected. To fully understand for
which images the builds will have access, read the
[New CI build permissions model][ci-build-permissions-model] documentation.

#### Precedence of Docker authorization resolving

As described above, GitLab Runner can authorize Docker against a registry by
using credentials sent in different way. To find a proper registry, the following
precedence is taken into account:

1. Credentials configured with `DOCKER_AUTH_CONFIG`.
1. Credentials configured locally on Runner's host with `~/.docker/config.json`
   or `~/.dockercfg` files (e.g., by running `docker login` on the host).
1. Credentials sent by default with job's payload (e.g., credentials for _integrated
   registry_ described above).

The first found credentials for the registry will be used. So for example,
if you add some credentials for the _integrated registry_ with the
`DOCKER_AUTH_CONFIG` variable, then the default credentials will be overridden.

#### Restrict `allowed_images` to private registry

For certain setups you will restrict access of the build jobs to docker images
which comes from your private docker registry. In that case set

```bash
[runners.docker]
  ...
  allowed_images = ["my.registry.tld:5000/*:*"]
```

## The [runners.parallels] section

This defines the Parallels parameters.

| Parameter | Description |
| --------- | ----------- |
| `base_name`         | name of Parallels VM which will be cloned |
| `template_name`     | custom name of Parallels VM linked template (optional) |
| `disable_snapshots` | if disabled the VMs will be destroyed after build |

Example:

```bash
[runners.parallels]
  base_name = "my-parallels-image"
  template_name = ""
  disable_snapshots = false
```

## The [runners.virtualbox] section

This defines the VirtualBox parameters. This executor relies on
`vboxmanage` as executable to control VirtualBox machines so you have to adjust
your `PATH` environment variable on Windows hosts:
`PATH=%PATH%;C:\Program Files\Oracle\VirtualBox`.

| Parameter | Explanation |
| --------- | ----------- |
| `base_name`         | name of VirtualBox VM which will be cloned |
| `base_snapshot`     | name or UUID of a specific snapshot of the VM from which to create a linked clone. If this is empty or omitted, the current snapshot will be used. If there is no current snapshot, one will be created unless `disable_snapshots` is true, in which case a full clone of the base VM will be made. |
| `disable_snapshots` | if disabled the VMs will be destroyed after build |

Example:

```bash
[runners.virtualbox]
  base_name = "my-virtualbox-image"
  base_snapshot = "my-image-snapshot"
  disable_snapshots = false
```

## The [runners.ssh] section

This defines the SSH connection parameters.

| Parameter  | Description |
| ---------- | ----------- |
| `host`     | where to connect (overridden when using `docker-ssh`) |
| `port`     | specify port, default: 22 |
| `user`     | specify user |
| `password` | specify password |
| `identity_file` | specify file path to SSH private key (id_rsa, id_dsa or id_edcsa). The file needs to be stored unencrypted |

Example:

```
[runners.ssh]
  host = "my-production-server"
  port = "22"
  user = "root"
  password = "production-server-password"
  identity_file = ""
```

## The [runners.machine] section

>**Note:**
Added in GitLab Runner v1.1.0.

This defines the Docker Machine based autoscaling feature. More details can be
found in the separate [runners autoscale documentation](autoscale.md).

| Parameter           | Description |
|---------------------|-------------|
| `IdleCount`         | Number of machines, that need to be created and waiting in _Idle_ state. |
| `IdleTime`          | Time (in seconds) for machine to be in _Idle_ state before it is removed. |
| `OffPeakPeriods`    | Time periods when the scheduler is in the OffPeak mode. An array of cron-style patterns (described below). |
| `OffPeakTimezone`   | Time zone for the times given in OffPeakPeriods. A timezone string like Europe/Berlin (defaults to the locale system setting of the host if omitted or empty). |
| `OffPeakIdleCount`  | Like `IdleCount`, but for _Off Peak_ time periods. |
| `OffPeakIdleTime`   | Like `IdleTime`, but for _Off Peak_ time mperiods. |
| `MaxBuilds`         | Builds count after which machine will be removed. |
| `MachineName`       | Name of the machine. It **must** contain `%s`, which will be replaced with a unique machine identifier. |
| `MachineDriver`     | Docker Machine `driver` to use. More details can be found in the [Docker Machine configuration section](autoscale.md#what-are-the-supported-cloud-providers). |
| `MachineOptions`    | Docker Machine options. More details can be found in the [Docker Machine configuration section](autoscale.md#what-are-the-supported-cloud-providers). |

Example:

```bash
[runners.machine]
  IdleCount = 5
  IdleTime = 600
  OffPeakPeriods = [
    "* * 0-10,18-23 * * mon-fri *",
    "* * * * * sat,sun *"
  ]
  OffPeakTimezone = "Europe/Berlin"
  OffPeakIdleCount = 1
  OffPeakIdleTime = 3600
  MaxBuilds = 100
  MachineName = "auto-scale-%s"
  MachineDriver = "digitalocean"
  MachineOptions = [
      "digitalocean-image=coreos-stable",
      "digitalocean-ssh-user=core",
      "digitalocean-access-token=DO_ACCESS_TOKEN",
      "digitalocean-region=nyc2",
      "digitalocean-size=4gb",
      "digitalocean-private-networking",
      "engine-registry-mirror=http://10.11.12.13:12345"
  ]
```

### OffPeakPeriods syntax

The `OffPeakPeriods` setting contains an array of string patterns of
time periods represented in a cron-style format. The line contains
following fields:

```
[second] [minute] [hour] [day of month] [month] [day of week] [year]
```

Like in the standard cron configuration file, the fields can contain single
values, ranges, lists and asterisks. A detailed description of the syntax
can be found [here][cronvendor].

## The [runners.cache] section

>**Note:**
Added in GitLab Runner v1.1.0.

This defines the distributed cache feature. More details can be found
in the [runners autoscale documentation](autoscale.md#distributed-runners-caching).

| Parameter        | Type             | Description |
|------------------|------------------|-------------|
| `Type`           | string           | As of now, only S3-compatible services are supported, so only `s3` can be used. |
| `ServerAddress`  | string           | A `host:port` to the used S3-compatible server. |
| `AccessKey`      | string           | The access key specified for your S3 instance. |
| `SecretKey`      | string           | The secret key specified for your S3 instance. |
| `BucketName`     | string           | Name of the bucket where cache will be stored. |
| `BucketLocation` | string           | Name of S3 region. |
| `Insecure`       | boolean          | Set to `true` if the S3 service is available by `HTTP`. Is set to `false` by default. |
| `Path`           | string           | Name of the path to prepend to the cache URL. |
| `Shared`         | boolean          | Enables cache sharing between runners, `false` by default. |

Example:

```bash
[runners.cache]
  Type = "s3"
  ServerAddress = "s3.amazonaws.com"
  AccessKey = "AMAZON_S3_ACCESS_KEY"
  SecretKey = "AMAZON_S3_SECRET_KEY"
  BucketName = "runners"
  BucketLocation = "eu-west-1"
  Insecure = false
  Path = "path/to/prefix"
  Shared = false
```

> **Note:** For Amazon's S3 service the `ServerAddress` should always be `s3.amazonaws.com`. Minio S3 client will
> get bucket metadata and modify the URL to point to the valid region (eg. `s3-eu-west-1.amazonaws.com`) itself.

## The [runners.kubernetes] section

> **Note:**
> Added in GitLab Runner v1.6.0

This defines the Kubernetes parameters.

| Parameter        | Type    | Description |
|------------------|---------|-------------|
| `host`           | string  | Optional Kubernetes master host URL (auto-discovery attempted if not specified) |
| `cert_file`      | string  | Optional Kubernetes master auth certificate |
| `key_file`       | string  | Optional Kubernetes master auth private key |
| `ca_file`        | string  | Optional Kubernetes master auth ca certificate |
| `image`          | string  | Default docker image to use for builds when none is specified |
| `namespace`      | string  | Namespace to run Kubernetes jobs in |
| `privileged`     | boolean | Run all containers with the privileged flag enabled |
| `node_selector`  | table   | A `table` of `key=value` pairs of `string=string`. Setting this limits the creation of pods to kubernetes nodes matching all the `key=value` pairs |
| `image_pull_secrets` | array | A list of secrets that are used to authenticate docker image pulling |

Example:

```bash
[runners.kubernetes]
	host = "https://45.67.34.123:4892"
	cert_file = "/etc/ssl/kubernetes/api.crt"
	key_file = "/etc/ssl/kubernetes/api.key"
	ca_file = "/etc/ssl/kubernetes/ca.crt"
	namespace = "gitlab"
	image = "golang:1.8"
	privileged = true
	image_pull_secrets = ["docker-registry-credentials"]
	[runners.kubernetes.node_selector]
		gitlab = "true"
```

## Note

If you'd like to deploy to multiple servers using GitLab CI, you can create a
single script that deploys to multiple servers or you can create many scripts.
It depends on what you'd like to do.

[TOML]: https://github.com/toml-lang/toml
[Docker Engine]: https://www.docker.com/docker-engine
[yaml-priv-reg]: https://docs.gitlab.com/ce/ci/yaml/README.html#image-and-services
[ci-build-permissions-model]: https://docs.gitlab.com/ce/user/project/new_ci_build_permissions_model.html
[secpull]: ../security/index.md#usage-of-private-docker-images-with-if-not-present-pull-policy
[priv-example]: https://docs.gitlab.com/ce/ci/docker/using_docker_images.html#define-an-image-from-a-private-docker-registry
[secret variable]: https://docs.gitlab.com/ce/ci/variables/#secret-variables
[cronvendor]: https://gitlab.com/gitlab-org/gitlab-ci-multi-runner/blob/master/vendor/github.com/gorhill/cronexpr/README.md
