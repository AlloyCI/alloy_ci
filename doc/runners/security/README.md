# Security of running jobs

When using GitLab Runner you should be aware of potential security implications
when running your jobs.

## Usage of Shell executor

**Generally it's unsafe to run tests with `shell` executors.** The jobs are run
with user's permissions and can steal code from other
projects that are run on this server. Use only it for running trusted builds.

## Usage of Docker executor

**Docker can be considered safe when run in non-privileged mode.** To make such
setup more secure it's advised to run jobs as user (non-root) in Docker containers
with disabled sudo or dropped `SETUID` and `SETGID` capabilities.

On the other hand there's privileged mode which enables full access to host system,
permission to mount and unmount volumes and run nested containers. It's not advised
to run containers in privileged mode.

More granular permissions can be configured in non-privileged mode via the
`cap_add`/`cap_drop` settings.

## Usage of private Docker images with `if-not-present` pull policy

When using the private Docker images support described in
[advanced configuration: using a private container registry](../configuration/advanced-configuration.md#using-a-private-container-registry)
you should use `always` as the `pull_policy` value. Especially you should
use `always` pull policy if you are hosting a public, shared Runner with the
Docker executor.

Let's consider such example, when pull policy is set to `if-not-present`:

1. User A has a private image at `registry.example.com/image/name`.
1. User A starts a build on a shared runner: The build receives registry
   credentials and pulls the image after authorization in registry.
1. Image is stored on shared runner's host.
1. User B doesn't have access to the private image at registry.example.com/image/name.
1. User B starts a build which is using this image on the same shared runner
   as User A: Runner find a local version of the image and uses it **even if
   the image could not be pulled because of missing credentials**.

Therefore, if you host a Runner that can be used by different users and
different projects (with mixed private, and public access levels) you should
never use `if-not-present` as the pull policy value, but use:

- `never` - if you want to limit users to use only image pre-downloaded by you,
- `always` - if you want to give users possibility to download any image from
  any registry.

The `if-not-present` pull policy should be used **only** for specific Runners
used by trusted builds and users.

Read the [pull policies documentation](../executors/docker.md#how-pull-policies-work)
for more information.

## Systems with Docker installed

>**Note:**
This applies to installations below 0.5.0 or one's that were upgraded to newer version.

When installing package on Linux systems with Docker installed, `gitlab-ci-multi-runner`
will create user that will have permission to access `Docker` daemon. This makes
the jobs run with `shell` executor able to access `docker` with full permissions
and potentially allows root access to the server.

## Usage of SSH executor

**SSH executors are susceptible to MITM attack (man-in-the-middle)**, because of
missing `StrictHostKeyChecking` option. This will be fixed in one of the future
releases.

## Usage of Parallels executor

**Parallels executor is the safest possible option**, because it uses full system
virtualization and with VM machines that are configured to run in isolated mode
it blocks access to all peripherals and shared folders.
