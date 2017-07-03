# FAQ

Some Frequently Asked Questions about GitLab Runner.

## What does `coordinator` mean?

The `coordinator` is the AlloyCI installation from which a job is requested.

In other words, runners are isolated (virtual) machines that pick up jobs
requested by their `coordinator`.

## Where are logs stored when run as a service?

+ If the GitLab Runner is run as service on Linux/OSX  the daemon logs to syslog.
+ If the GitLab Runner is run as service on Windows it logs to System's Event Log.

## Run in `--debug` mode

Is it possible to run GitLab Runner in debug/verbose mode. From a terminal, do:

```
gitlab-runner --debug run
```

## I get a PathTooLongException during my builds on Windows

This is caused by tools like `npm` which will sometimes generate directory structures
with paths more than 260 characters in length. There are two possible fixes you can
adopt to solve the problem.

### a) Use Git with core.longpaths enabled

You can avoid the problem by using Git to clean your directory structure, first run
`git config --system core.longpaths true` from the command line and then set your
project to use *git fetch* from the GitLab CI project settings page.

### b) Use NTFSSecurity tools for PowerShell

The [NTFSSecurity](https://ntfssecurity.codeplex.com/) PowerShell module provides
a *Remove-Item2* method which supports long paths. The Gitlab CI Multi Runner will
detect it if it is available and automatically make use of it.

## I'm seeing `x509: certificate signed by unknown authority`

Please [See the self-signed certificates](../configuration/tls-self-signed.md)

## I get `Permission Denied` when accessing the `/var/run/docker.sock`

If you want to use Docker executor,
and you are connecting to Docker Engine installed on server.
You can see the `Permission Denied` error.
The most likely cause is that your system uses SELinux (enabled by default on CentOS, Fedora and RHEL).
Check your SELinux policy on your system for possible denials.

## The Docker executor gets timeout when building Java project.

This most likely happens, because of the broken AUFS storage driver:
[Java process hangs on inside container](https://github.com/docker/docker/issues/18502).
The best solution is to change the [storage driver](https://docs.docker.com/engine/userguide/storagedriver/selectadriver/)
to either OverlayFS (faster) or DeviceMapper (slower).

Check this article about [configuring and running Docker](https://docs.docker.com/engine/articles/configuring/)
or this article about [control and configure with systemd](https://docs.docker.com/engine/articles/systemd/).

## I get 411 when uploading artifacts.

This happens due to fact that runner uses `Transfer-Encoding: chunked` which is broken on early version of Nginx (http://serverfault.com/questions/164220/is-there-a-way-to-avoid-nginx-411-content-length-required-errors).

Upgrade your Nginx to newer version, if you are using Nginx to serve your AlloyCI
installation.

## I can't run Windows BASH scripts; I'm getting `The system cannot find the batch label specified - buildscript`.

You need to prepend `call` to your batch file line in .alloy-ci.json so that it looks like `call C:\path\to\test.bat`. Here
is a more complete example:

```json
"before_script": [
  "call C:\path\to\test.bat"
]
```

## My gitlab runner is on Windows. How can I get colored output on the web terminal?

**Short answer:**

Make sure that you have the ANSI color codes in your program's output. For the purposes of text formatting, assume that you're
running in a UNIX ANSI terminal emulator (because that's what the webUI's output is).

**Long Answer:**

The web interface for AlloyCI emulates a UNIX ANSI terminal (at least partially). The `gitlab-runner` pipes any output from the build
directly to the web interface. That means that any ANSI color codes that are present will be honored.

Windows' CMD terminal (before Win10 ([source](http://www.nivot.org/blog/post/2016/02/04/Windows-10-TH2-(v1511)-Console-Host-Enhancements)))
does not support ANSI color codes - it uses win32 ([`ANSI.SYS`](https://en.wikipedia.org/wiki/ANSI.SYS)) calls instead which are **not** present in
the string to be displayed. When writing cross-platform programs, a developer will typically use ANSI color codes by default and convert
them to win32 calls when running on a Windows system (example: [Colorama](https://pypi.python.org/pypi/colorama)).

If your program is doing the above, then you need to disable that conversion for the CI builds so that the ANSI codes remain in the string.

See issue [#332](https://gitlab.com/gitlab-org/gitlab-ci-multi-runner/issues/332) for more information.

## `"launchctl" failed: exit status 112, Could not find domain for`

This message may occur when you try to install GitLab Runner on OSX. Make sure
that you manage GitLab Runner service from the GUI Terminal application, not
the SSH connection.

## `Failed to authorize rights (0x1) with status: -60007.`

If your Runner is stuck on the above message when using OSX, there are two
causes to why this happens:

1. Make sure that your user can perform UI interactions:

    ```bash
    DevToolsSecurity -enable
    sudo security authorizationdb remove system.privilege.taskport is-developer
    ```

    The first command enables access to developer tools for your user.
    The second command allows the user who is member of the developer group to
    do UI interactions, e.g., run the iOS simulator.

    ---

2. Make sure that your Runner service doesn't use `SessionCreate = true`.
   Previously, when running GitLab Runner as a service, we were creating
   `LaunchAgents` with `SessionCreate`. At that point (**Mavericks**), this was
   the only solution to make Code Signing work. That changed recently with
   **OSX El Capitan** which introduced a lot of new security features that
   altered this behavior.
   Since GitLab Runner 1.1, when creating a `LaunchAgent`, we don't set
   `SessionCreate`. However, in order to upgrade, you need to manually
   reinstall the `LaunchAgent` script:

    ```
    gitlab-runner uninstall
    gitlab-runner install
    gitlab-runner start
    ```

    Then you can verify that `~/Library/LaunchAgents/gitlab-runner.plist` has
    `SessionCreate` set to `false`.

## `The service did not start due to a logon failure` error when starting service on Windows

When installing and starting the GitLab Runner service on Windows you can
meet with such error:

```
$ gitlab-runner install --password WINDOWS_MACHINE_PASSWORD
$ gitlab-runner start
$ FATA[0000] Failed to start GitLab Runner: The service did not start due to a logon failure.
```

This error can occur when the user used to execute the service doesn't have
the `SeServiceLogonRight` permission. In such case you need to add this
permission for the chosen user and then try to start the service again.

You can add `SeServiceLogonRight` in two ways:

1. Manually using Administrative Tools:
   - Go to _Control Panel > System and Security > Administrative Tools_,
   - open the _Local Security Policy_ tool,
   - chose the _Security Settings > Local Policies > User Rights Assignment_ on the
     list on the left,
   - open the _Log on as a service_ on the list on the right,
   - click on the _Add User or Group..._ button,
   - add the user ("by hand" or using _Advanced..._ button) and apply the settings.

     > **Notice:** According to [Microsoft's documentation][microsoft-manually-set-seservicelogonright]
     > this should work for: Windows Vista, Windows Server 2008, Windows 7, Windows 8.1,
     > Windows Server 2008 R2, Windows Server 2012 R2, Windows Server 2012, Windows 8

     > **Notice:** The _Local Security Policy_ tool may be not available in some
     > Windows versions - for example in "Home Edition" variant of each version.

1. From command line, using the `Ntrights.exe` tool:
   - Download tools from [Microsoft's download site][microsoft-ntrights-download],
   - execute `ntrights.exe ntrights +r SeServiceLogonRight -u USER_NAME_HERE` (remember,
     that you should provide a full path for `ntrights.exe` executable **or** add that
     path to system's `PATH` environment variable).

     > **Notice:** The tool was created in 2003 and was initially designed to use
     > with Windows XP and Windows Server 2003. On [Microsoft sites][microsoft-ntrights-usage-on-win7]
     > you can find an example of usage `Ntrights.exe` that applies to Windows 7 and Windows Server 2008 R2.
     > This solution is not tested and because of the age of the software **it may not work
     > on newest Windows versions**.

After adding the `SeServiceLogonRight` for the user used in service configuration,
the command `gitlab-runner start` should finish without failures
and the service should be started properly.

[microsoft-manually-set-seservicelogonright]: https://technet.microsoft.com/en-us/library/dn221981
[microsoft-ntrights-download]: https://www.microsoft.com/en-us/download/details.aspx?id=17657
[microsoft-ntrights-usage-on-win7]: https://technet.microsoft.com/en-us/library/dd548356(WS.10).aspx

## `zoneinfo.zip: no such file or directory` error when using `OffPeakTimezone`

In `v1.11.0` we made it possible to configure the timezone in which `OffPeakPeriods`
are described. This feature should work on most Unix systems out of the box. However on some
Unix systems, and probably on most non-Unix systems (including Windows, for which we're providing
Runner's binaries), when used, the Runner will crash at start with an error similar to:

```
Failed to load config Invalid OffPeakPeriods value: open /usr/local/go/lib/time/zoneinfo.zip: no such file or directory
```

The error is caused by the `time` package in Go. Go uses the IANA Time Zone database to load
the configuration of the specified timezone. On most Unix systems, this database is already present on
one of well-known paths (`/usr/share/zoneinfo`, `/usr/share/lib/zoneinfo`, `/usr/lib/locale/TZ/`).
Go's `time` package looks for the Time Zone database in all those three paths. If it doesn't find any
of them, but the machine has a configured Go development environment (with a proper `$GOPATH`
present for Runner's process), then it will fallback to the `$GOROOT/lib/time/zoneinfo.zip` file.

If none of those paths are present (for example on a production Windows host) the above error is thrown.

In case your system has support for the IANA Time Zone database, but it's not available by default, you
can try to install it. For Linux systems it can be done for example by:

```bash
# on Debian/Ubuntu based systems
sudo apt-get install tzdata

# on RPM based systems
sudo yum install tzdata

# on Linux Alpine
sudo apk add -U tzdata
```

If your system doesn't provide this database in a _native_ way, then you can make `OffPeakTimezone`
working by following the steps below:

1. Downloading the [`zoneinfo.zip`][zoneinfo-file]. Starting with version v9.1.0 you can download
   the file from a tagged path. In that case you should replace `latest` with the tag name (e.g., `v9.1.0`)
   in the `zoneinfo.zip` download URL.

1. Store this file in a well known directory. We're suggesting to use the same directory where
   the `config.toml` file is present. So for example, if you're hosting Runner on Windows machine
   and your config file is stored at `C:\gitlab-runner\config.toml`, then save the `zoneinfo.zip`
   at `C:\gitlab-runner\zoneinfo.zip`.

1. Set the `ZONEINFO` environment variable containing a full path to the `zoneinfo.zip` file. If you
   are starting the Runner using the `run` command, then you can do this with:

    ```bash
    ZONEINFO=/etc/gitlab-runner/zoneinfo.zip gitlab-runner run [other options ...]
    ```

    or if using Windows:

    ```powershell
    C:\gitlab-runner> set ZONEINFO=C:\gitlab-runner\zoneinfo.zip
    C:\gitlab-runner> gitlab-runner run [other options ...]
    ```

    If you are starting the Runner as a system service then you will need to update/override
    the service configuration in a way that is provided by your service manager software
    (unix systems) or by adding the `ZONEINFO` variable to the list of environment variables
    available for Runner's user through System Settings (Windows).

[zoneinfo-file]: https://gitlab-ci-multi-runner-downloads.s3.amazonaws.com/latest/zoneinfo.zip
