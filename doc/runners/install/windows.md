# Install on Windows

To install and run GitLab Runner on Windows you need:
* Git installed
* A password for your user account, if you want to run it under your user
  account rather than the Built-in System Account

## Installation

1. Create a folder somewhere in your system, ex.: `C:\GitLab-Runner`.
1. Download the binary for [x86][]  or [amd64][] and put it into the folder you
   created. Rename the binary to `gitlab-runner.exe`.
   You can download a binary for every available version as described in
   [Bleeding Edge - download any other tagged release](bleeding-edge.md#download-any-other-tagged-release).
1. Run an [`Administrator`/elevated command prompt][prompt] (<kbd>WindowsKey</kbd> + <kbd>X</kbd> then select Command Prompt (Admin)).
1. [Register the Runner](../register/index.md).
1. Install the Runner as a service and start it. You can either run the service
   using the Built-in System Account (recommended) or using a user account.

    **Run service using Built-in System Account**

    ```bash
    gitlab-runner install
    gitlab-runner start
    ```

    **Run service using user account**

    You have to enter a valid password for the current user account, because
    it's required to start the service by Windows:

    ```bash
    gitlab-runner install --user ENTER-YOUR-USERNAME --password ENTER-YOUR-PASSWORD
    gitlab-runner start
    ```

    See the [troubleshooting section](#troubleshooting) if you encounter any
    errors during the Runner installation.

1. (Optional) Update Runners `concurrent` value in `C:\GitLab-Runner\config.toml`
   to allow multiple concurrent jobs as detailed in [advanced configuration details](../configuration/advanced-configuration.md).
   Additionally you can use the advanced configuration details to update your
   shell executor to use Bash or PowerShell rather than Batch.

Voila! Runner is installed, running, and will start again after each system reboot.
Logs are stored in Windows Event Log.

## Update

1. Stop the service (you need elevated command prompt as before):

    ```bash
    cd C:\GitLab-Runner
    gitlab-runner stop
    ```

1. Download the binary for [x86][] or [amd64][] and replace runner's executable.

   You can download a binary for every available version as described in
   [Bleeding Edge - download any other tagged release](bleeding-edge.md#download-any-other-tagged-release).

1. Start the service:

    ```bash
    gitlab-runner start
    ```

## Uninstall

From elevated command prompt:

```bash
cd C:\GitLab-Runner
gitlab-runner stop
gitlab-runner uninstall
cd ..
rmdir /s GitLab-Runner
```

## Troubleshooting

Make sure that you read the [FAQ](../faq/README.md) section which describes
some of the most common problems with GitLab Runner.

If you encounter an error like _The account name is invalid_ try to add `.\` before the username:

```shell
gitlab-runner install --user ".\ENTER-YOUR-USERNAME" --password "ENTER-YOUR-PASSWORD"
```

If you encounter a _The service did not start due to a logon failure_ error
while starting the service, please [look in the FAQ](../faq/README.md#13-the-service-did-not-start-due-to-a-logon-failure-error-when-starting-service-on-windows) to check how to resolve the problem.

If you don't have a Windows Password, Runner's service won't start but you can
use the Built-in System Account.

If you have issues with the Built-in System Account, please read
[How to Configure the Service to Start Up with the Built-in System Account](https://support.microsoft.com/en-us/kb/327545#6)
on Microsoft's support website.

[x86]: https://gitlab-ci-multi-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-ci-multi-runner-windows-386.exe
[amd64]: https://gitlab-ci-multi-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-ci-multi-runner-windows-amd64.exe
[prompt]: https://www.tenforums.com/tutorials/2790-elevated-command-prompt-open-windows-10-a.html
