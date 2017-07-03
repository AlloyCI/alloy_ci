# Install on FreeBSD

>**Notes:**
- The FreeBSD version is also available as a [bleeding edge](bleeding-edge.md)
  release.
- Make sure that you read the [FAQ](../faq/README.md) section which describes
  some of the most common problems with GitLab Runner.

Here are the steps to install and configure GitLab Runner under FreeBSD:

1. Create the `gitlab-runner` user and group:

    ```bash
    sudo pw group add -n gitlab-runner
    sudo pw user add -n gitlab-runner -g gitlab-runner -s /usr/local/bin/bash
    sudo mkdir /home/gitlab-runner
    sudo chown gitlab-runner:gitlab-runner /home/gitlab-runner
    ```

1. Download the binary for your system:

    ```bash
    # For amd64
    sudo wget -O /usr/local/bin/gitlab-runner https://gitlab-ci-multi-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-ci-multi-runner-freebsd-amd64

    # For i386
    sudo wget -O /usr/local/bin/gitlab-runner https://gitlab-ci-multi-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-ci-multi-runner-freebsd-386
    ```

    You can download a binary for every available version as described in
    [Bleeding Edge - download any other tagged release](bleeding-edge.md#download-any-other-tagged-release).

1. Give it permissions to execute:

    ```bash
    sudo chmod +x /usr/local/bin/gitlab-runner
    ```

1. Create an empty log file with correct permissions:

    ```bash
    sudo touch /var/log/gitlab_runner.log && sudo chown gitlab-runner:gitlab-runner /var/log/gitlab_runner.log
    ```

1. Create the `rc.d` directory in case it doesn't exist:

    ```bash
    mkdir -p /usr/local/etc/rc.d
    ```

1. Create the `rc.d` script:

    ```bash
    sudo bash -c 'cat > /usr/local/etc/rc.d/gitlab_runner' << "EOF"
    #!/bin/sh
    # PROVIDE: gitlab_runner
    # REQUIRE: DAEMON NETWORKING
    # BEFORE:
    # KEYWORD:

    . /etc/rc.subr

    name="gitlab_runner"
    rcvar="gitlab_runner_enable"

    load_rc_config $name

    user="gitlab-runner"
    user_home="/home/gitlab-runner"
    command="/usr/local/bin/gitlab-runner run"
    pidfile="/var/run/${name}.pid"

    start_cmd="gitlab_runner_start"
    stop_cmd="gitlab_runner_stop"
    status_cmd="gitlab_runner_status"

    gitlab_runner_start()
    {
        export USER=${user}
        export HOME=${user_home}
        if checkyesno ${rcvar}; then
            cd ${user_home}
            /usr/sbin/daemon -u ${user} -p ${pidfile} ${command} > /var/log/gitlab_runner.log 2>&1
        fi
    }

    gitlab_runner_stop()
    {
        if [ -f ${pidfile} ]; then
            kill `cat ${pidfile}`
        fi
    }

    gitlab_runner_status()
    {
        if [ ! -f ${pidfile} ] || kill -0 `cat ${pidfile}`; then
            echo "Service ${name} is not running."
        else
            echo "${name} appears to be running."
        fi
    }

    run_rc_command $1
    EOF
    ```

1. Make it executable:

    ```bash
    sudo chmod +x /usr/local/etc/rc.d/gitlab_runner
    ```

1. [Register the Runner](../register/index.md)
1. Enable the `gitlab-runner` service and start it:

    ```bash
    sudo sysrc -f /etc/rc.conf "gitlab_runner_enable=YES"
    sudo service gitlab_runner start
    ```

    If you don't want to enable the `gitlab-runner` service to start after a
    reboot, use:

    ```bash
    sudo service gitlab_runner onestart
    ```
