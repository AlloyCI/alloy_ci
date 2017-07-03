# Install GitLab Runner using the official GitLab repositories

Currently we support:

- Debian
- Ubuntu
- RHEL
- CentOS

If you want to use the [Docker executor], install it before using the Runner:

```bash
curl -sSL https://get.docker.com/ | sh
```

## Installing the Runner

To install the Runner:

1. Add GitLab's official repository:

    ```bash
    # For Debian/Ubuntu
    curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-ci-multi-runner/script.deb.sh | sudo bash

    # For RHEL/CentOS
    curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-ci-multi-runner/script.rpm.sh | sudo bash
    ```

    >**Note:**
    _Debian users should use APT pinning_
    >
    Since Debian Stretch, Debian maintainers added their native package
    with the same name as is used by our package, and by default the official
    repositories will have a higher priority.
    >
    If you want to use our package you should manually set the source of
    the package. The best would be to add the pinning configuration file.
    Thanks to this every next update of the Runner's package - whether it will
    be done manually or automatically - will be done using the same source:
    >
    ```bash
    cat > /etc/apt/preferences.d/pin-gitlab-runner.pref <<EOF
    Explanation: Prefer GitLab provided packages over the Debian native ones
    Package: gitlab-ci-multi-runner
    Pin: origin packages.gitlab.com
    Pin-Priority: 1001
    EOF
    ```

1. Install `gitlab-ci-multi-runner`:

    ```bash
    # For Debian/Ubuntu
    sudo apt-get install gitlab-ci-multi-runner

    # For RHEL/CentOS
    sudo yum install gitlab-ci-multi-runner
    ```

1. [Register the Runner](../register/index.md)

After completing the step above, he Runner should be started already being
ready to be used by your projects!

Make sure that you read the [FAQ](../faq/README.md) section which describes
some of the most common problems with GitLab Runner.

## Updating the Runner

Simply execute to install latest version:

```bash
# For Debian/Ubuntu
sudo apt-get update
sudo apt-get install gitlab-ci-multi-runner

# For RHEL/CentOS
sudo yum update
sudo yum install gitlab-ci-multi-runner
```

## Manually download packages

You can manually download the packages from the following URL:
<https://packages.gitlab.com/runner/gitlab-ci-multi-runner>

[docker executor]: ../executors/docker.md
