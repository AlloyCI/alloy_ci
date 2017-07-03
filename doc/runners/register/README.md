# Registering Runners

Registering a Runner is the process that binds the Runner with an AlloyCI instance.

## Prerequisites

Before registering a Runner, you need to first:

- [Install it](../install/README.md) on a server separate than where AlloyCI
  is installed on
- [Obtain a token](https://docs.gitlab.com/ce/ci/runners/) for a shared or
  specific Runner via AlloyCI's interface

## GNU/Linux

To register a Runner under GNU/Linux:

1. Run the following command:

    ```sh
    sudo gitlab-runner register
    ```

1. Enter your AlloyCI instance URL:

    ```
    Please enter the gitlab-ci coordinator URL (e.g. https://alloy-ci.com )
    https://alloy-ci.com
    ```

1. Enter the token you obtained to register the Runner:

    ```
    Please enter the gitlab-ci token for this runner
    xxx
    ```

1. Enter a description for the Runner, you can change this later in GitLab's
   UI:

    ```
    Please enter the gitlab-ci description for this runner
    [hostame] my-runner
    ```

1. Enter the [tags associated with the Runner][tags], you can change this later in GitLab's UI:

    ```
    Please enter the gitlab-ci tags for this runner (comma separated):
    my-tag,another-tag
    ```

1. Choose whether the Runner should pick up jobs that do not [have tags][tags],
   you can change this later in GitLab's UI (defaults to false):

    ```
    Whether to run untagged jobs [true/false]:
    [false]: true
    ```

1. Choose whether to lock the Runner to the current project, you can change
   this later in GitLab's UI. Useful when the Runner is specific (defaults to
   false):

    ```
    Whether to lock Runner to current project [true/false]:
    [false]: false
    ```

1. Enter the [Runner executor](../executors/README.md):

    ```
    Please enter the executor: ssh, docker+machine, docker-ssh+machine, kubernetes, docker, parallels, virtualbox, docker-ssh, shell:
    docker
    ```

1. If you chose Docker as your executor, you'll be asked for the default
   image to be used for projects that do not define one in `.gitlab-ci.yml`:

    ```
    Please enter the Docker image (eg. ruby:2.1):
    alpine:latest
    ```

## macOS

To register a Runner under macOS:

1. Run the following command:

    ```sh
    gitlab-runner register
    ```

1. Enter your GitLab instance URL:

    ```
    Please enter the gitlab-ci coordinator URL (e.g. https://gitlab.com )
    https://gitlab.com
    ```

1. Enter the token you obtained to register the Runner:

    ```
    Please enter the gitlab-ci token for this runner
    xxx
    ```

1. Enter a description for the Runner, you can change this later in GitLab's
   UI:

    ```
    Please enter the gitlab-ci description for this runner
    [hostame] my-runner
    ```

1. Enter the [tags associated with the Runner][tags], you can change this later in GitLab's UI:

    ```
    Please enter the gitlab-ci tags for this runner (comma separated):
    my-tag,another-tag
    ```

1. Choose whether the Runner should pick up jobs that do not [have tags][tags],
   you can change this later in GitLab's UI (defaults to false):

    ```
    Whether to run untagged jobs [true/false]:
    [false]: true
    ```

1. Choose whether to lock the Runner to the current project, you can change
   this later in GitLab's UI. Useful when the Runner is specific (defaults to
   false):

    ```
    Whether to lock Runner to current project [true/false]:
    [false]: false
    ```

1. Enter the [Runner executor](../executors/README.md):

    ```
    Please enter the executor: ssh, docker+machine, docker-ssh+machine, kubernetes, docker, parallels, virtualbox, docker-ssh, shell:
    docker
    ```

1. If you chose Docker as your executor, you'll be asked for the default
   image to be used for projects that do not define one in `.gitlab-ci.yml`:

    ```
    Please enter the Docker image (eg. ruby:2.1):
    alpine:latest
    ```
    **Note** _[be sure Docker.app is installed on your mac](https://docs.docker.com/docker-for-mac/install/)_

## Windows

To register a Runner under Windows:

1. Run the following command:

    ```sh
    ./gitlab-runner.exe register
    ```

1. Enter your GitLab instance URL:

    ```
    Please enter the gitlab-ci coordinator URL (e.g. https://gitlab.com )
    https://gitlab.com
    ```

1. Enter the token you obtained to register the Runner:

    ```
    Please enter the gitlab-ci token for this runner
    xxx
    ```

1. Enter a description for the Runner, you can change this later in GitLab's
   UI:

    ```
    Please enter the gitlab-ci description for this runner
    [hostame] my-runner
    ```

1. Enter the [tags associated with the Runner][tags], you can change this later in GitLab's UI:

    ```
    Please enter the gitlab-ci tags for this runner (comma separated):
    my-tag,another-tag
    ```

1. Choose whether the Runner should pick up jobs that do not [have tags][tags],
   you can change this later in GitLab's UI (defaults to false):

    ```
    Whether to run untagged jobs [true/false]:
    [false]: true
    ```

1. Choose whether to lock the Runner to the current project, you can change
   this later in GitLab's UI. Useful when the Runner is specific (defaults to
   false):

    ```
    Whether to lock Runner to current project [true/false]:
    [false]: false
    ```

1. Enter the [Runner executor](../executors/README.md):

    ```
    Please enter the executor: ssh, docker+machine, docker-ssh+machine, kubernetes, docker, parallels, virtualbox, docker-ssh, shell:
    docker
    ```

1. If you chose Docker as your executor, you'll be asked for the default
   image to be used for projects that do not define one in `.gitlab-ci.yml`:

    ```
    Please enter the Docker image (eg. ruby:2.1):
    alpine:latest
    ```

If you'd like to register multiple Runners on the same machine with different
configurations repeat the `./gitlab-runner.exe register` command.

## FreeBSD

To register a Runner under FreeBSD:

1. Run the following command:

    ```sh
    sudo -u gitlab-runner -H /usr/local/bin/gitlab-runner register
    ```

1. Enter your GitLab instance URL:

    ```
    Please enter the gitlab-ci coordinator URL (e.g. https://gitlab.com )
    https://gitlab.com
    ```

1. Enter the token you obtained to register the Runner:

    ```
    Please enter the gitlab-ci token for this runner
    xxx
    ```

1. Enter a description for the Runner, you can change this later in GitLab's
   UI:

    ```
    Please enter the gitlab-ci description for this runner
    [hostame] my-runner
    ```

1. Enter the [tags associated with the Runner][tags], you can change this later in GitLab's UI:

    ```
    Please enter the gitlab-ci tags for this runner (comma separated):
    my-tag,another-tag
    ```

1. Choose whether the Runner should pick up jobs that do not [have tags][tags],
   you can change this later in GitLab's UI (defaults to false):

    ```
    Whether to run untagged jobs [true/false]:
    [false]: true
    ```

1. Choose whether to lock the Runner to the current project, you can change
   this later in GitLab's UI. Useful when the Runner is specific (defaults to
   false):

    ```
    Whether to lock Runner to current project [true/false]:
    [false]: false
    ```

1. Enter the [Runner executor](../executors/README.md):

    ```
    Please enter the executor: ssh, docker+machine, docker-ssh+machine, kubernetes, docker, parallels, virtualbox, docker-ssh, shell:
    docker
    ```

1. If you chose Docker as your executor, you'll be asked for the default
   image to be used for projects that do not define one in `.gitlab-ci.yml`:

    ```
    Please enter the Docker image (eg. ruby:2.1):
    alpine:latest
    ```

## Docker

To register a Runner using a Docker container:

1. Run the following command:

    ```sh
    docker exec -it gitlab-runner gitlab-runner register
    ```

1. Enter your GitLab instance URL:

    ```
    Please enter the gitlab-ci coordinator URL (e.g. https://gitlab.com )
    https://gitlab.com
    ```

1. Enter the token you obtained to register the Runner:

    ```
    Please enter the gitlab-ci token for this runner
    xxx
    ```

1. Enter a description for the Runner, you can change this later in GitLab's
   UI:

    ```
    Please enter the gitlab-ci description for this runner
    [hostame] my-runner
    ```

1. Enter the [tags associated with the Runner][tags], you can change this later in GitLab's UI:

    ```
    Please enter the gitlab-ci tags for this runner (comma separated):
    my-tag,another-tag
    ```

1. Choose whether the Runner should pick up jobs that do not [have tags][tags],
   you can change this later in GitLab's UI (defaults to false):

    ```
    Whether to run untagged jobs [true/false]:
    [false]: true
    ```

1. Choose whether to lock the Runner to the current project, you can change
   this later in GitLab's UI. Useful when the Runner is specific (defaults to
   false):

    ```
    Whether to lock Runner to current project [true/false]:
    [false]: false
    ```

1. Enter the [Runner executor](../executors/README.md):

    ```
    Please enter the executor: ssh, docker+machine, docker-ssh+machine, kubernetes, docker, parallels, virtualbox, docker-ssh, shell:
    docker
    ```

1. If you chose Docker as your executor, you'll be asked for the default
   image to be used for projects that do not define one in `.gitlab-ci.yml`:

    ```
    Please enter the Docker image (eg. ruby:2.1):
    alpine:latest
    ```

[tags]: ../README.md/#using-tags
