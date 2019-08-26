# Configuration of your jobs with .alloy-ci.yml

This document describes the usage of `.alloy-ci.yml`, the file that is used to
tell AlloyCI Runner how to manage your project's jobs.

## .alloy-ci.yml

AlloyCI uses a [YAML](https://en.wikipedia.org/wiki/YAML)
file (`.alloy-ci.yml`) for the project configuration. It is placed in the root
of your repository and contains definitions of how your project should be built.

If you have an existing `.gitlab-ci.yml` file, all you need to do is rename it to
`.alloy-ci.yml`.

The YAML file defines a set of jobs with constraints stating when they should
be run. The jobs are defined as top-level elements with a name and always have
to contain at least the `script` clause:

```yaml
job1:
  script:
  - execute-script-for-job1
job2:
  script:
  - execute-script-for-job2
```

The above example is the simplest possible CI configuration with two separate
jobs, where each of the jobs executes a different command.

Of course a command can execute code directly (`./configure;make;make install`)
or run a script (`test.sh`) in the repository.

Jobs are picked up by [Runners](../runners/README.md) and executed within the
environment of the Runner. What is important, is that each job is run
independently from each other.

The YAML syntax allows for using more complex job specifications than in the
above example:

```yaml
image: elixir:latest
services:
- postgres
before_script:
- mix deps.get
after_script:
- rm secrets
stages:
- build
- test
- deploy
job1:
  stage: build
  script:
  - execute-script-for-job1
  tags:
  - docker
```

There are a few reserved `keywords` that **cannot** be used as job names:

| Keyword       | Required | Description |
|---------------|----------|-------------|
| image         | no | Use docker image, covered in [Use Docker](../docker/README.md) |
| services      | no | Use docker services, covered in [Use Docker](../docker/README.md) |
| stages        | no | Define build stages |
| before_script | no | Define commands that run before each job's script |
| after_script  | no | Define commands that run after each job's script |
| variables     | no | Define build variables |
| cache         | no | Define list of files that should be cached between subsequent runs |

### image and services

This allows to specify a custom Docker image and a list of services that can be
used for time of the job. The configuration of this feature is covered in
[a separate document](../docker/README.md).

### before_script

`before_script` is used to define the command that should be run before all
jobs, including deploy jobs, but after the restoration of artifacts. This must
be an array.

### after_script

> Requires Gitlab Runner v1.2

`after_script` is used to define the command that will be run after for all
jobs, including failed ones. This has to be an array.

> **Note:**
The `before_script` and the main `script` are concatenated and run in a single context/container.
The `after_script` is run separately, so depending on the executor, changes done
outside of the working tree might not be visible, e.g. software installed in the
`before_script`.

### stages

`stages` is used to define stages that can be used by jobs.
The specification of `stages` allows for having flexible multi stage pipelines.

The ordering of elements in `stages` defines the ordering of jobs' execution:

1. Jobs of the same stage are run in parallel.
1. Jobs of the next stage are run after the jobs from the previous stage
   complete successfully.

Let's consider the following example, which defines 3 stages:

```yaml
stages:
- build
- test
- deploy
```

1. First, all jobs of `build` are executed in parallel.
1. If all jobs of `build` succeed, the `test` jobs are executed in parallel.
1. If all jobs of `test` succeed, the `deploy` jobs are executed in parallel.
1. If all jobs of `deploy` succeed, the commit is marked as `success`.
1. If any of the previous jobs fails, the commit is marked as `failed` and no
   jobs of further stage are executed.

There are also two edge cases worth mentioning:

1. If no `stages` are defined in `.alloy-ci.yml`, then the `build`,
   `test` and `deploy` are allowed to be used as job's stage by default.
2. If a job doesn't specify a `stage`, the job is assigned the `test` stage.

### variables

AlloyCI allows you to add variables to `.alloy-ci.yml` that are set in the
job environment. The variables are stored in the Git repository and are meant
to store non-sensitive project configuration, for example:

```yaml
variables:
  DATABASE_URL: postgres://postgres@postgres/my_database
```

>**Note:**
Only strings are legal for both for variable's name and value.
Floats or Integers are not legal and cannot be used.

These variables can be later used in all executed commands and scripts.
The YAML-defined variables are also set to all created service containers,
thus allowing to fine tune them. Variables can be also defined on a
[job level](#job-variables).

Except for the user defined variables, there are also the ones set up by the
Runner itself. One example would be `CI_COMMIT_REF_NAME` which has the value of
the branch or tag name for which project is built. Apart from the variables
you can set in `.alloy-ci.yml`, there are also the so called secret variables
which can be set in AlloyCI's UI.

[Learn more about variables.][variables]

### cache

`cache` is used to specify a list of files and directories which should be
cached between jobs. You can only use paths that are within the project
workspace.

If `cache` is defined outside the scope of jobs, it means it is set
globally and all jobs will use that definition.

Cache all files in `binaries` and `.config`:

```yaml
rspec:
  script:
  - test
  cache:
    paths:
    - binaries/
    - ".config"
```

Cache all Git untracked files:

```yaml
rspec:
  script:
  - test
  cache:
    untracked: true

```

Cache all Git untracked files and files in `binaries`:

```yaml
rspec:
  script:
  - test
  cache:
    untracked: true
    paths:
    - binaries/

```

Locally defined cache overrides globally defined options. The following `rspec`
job will cache only `binaries/`:

```yaml
cache:
  paths:
  - my/files
rspec:
  script:
  - test
  cache:
    paths:
    - binaries/

```

Note that since cache is shared between jobs cache content can be overwritten.

The cache is provided on a best-effort basis, so don't expect that the cache
will be always present. For implementation details, please check AlloyCI Runner.

## Jobs

`.alloy-ci.yml` allows you to specify an unlimited number of jobs. Each job
must have a unique name, which is not one of the keywords mentioned above.
A job is defined by a list of parameters that define the job behavior.

```yaml
job_name:
  script:
  - rake spec
  - coverage
  stage: test
  only:
  - master
  except:
  - develop
  tags:
  - ruby
  - postgres
  allow_failure: true
```

| Keyword       | Required | Description | Type |
|---------------|----------|-------------|------|
| script        | yes      | Defines a shell script which is executed by Runner | String |
| image         | no       | Use docker image, covered in [Using Docker Images](../docker/README.md) | String or YAML Object |
| services      | no       | Use docker services, covered in [Using Docker Images](../docker/README.md) | Array of: Strings or YAML Objects  |
| stage         | no       | Defines a job stage (default: `test`) | String |
| variables     | no       | Define job variables on a job level | YAML Object |
| only          | no       | Defines a list of git refs for which job is created | Array of Strings |
| except        | no       | Defines a list of git refs for which job is not created | Array of Strings |
| tags          | no       | Defines a list of tags which are used to select Runner | Array of Strings |
| allow_failure | no       | Allow job to fail. Failed job doesn't contribute to commit status | Boolean |
| when          | no       | Define when to run job. Can be `on_success`, `on_failure`, `always` or `manual` | String |
| dependencies  | no       | Define other jobs that a job depends on so that you can pass artifacts between them | Array of Strings |
| artifacts     | no       | Define list of job artifacts | YAML Object |
| cache         | no       | Define list of files that should be cached between subsequent runs | YAML Object |
| before_script | no       | Override a set of commands that are executed before job | Array of Strings |
| after_script  | no       | Override a set of commands that are executed after job | Array of Strings |

### script

`script` is a shell script which is executed by the Runner. For example:

```yaml
job:
  script:
  - bundle exec rspec
```

This parameter can also contain several commands using a list:

```yaml
job:
  script:
  - bundle exec rspec
  - uname -a
```

### stage

`stage` allows to group jobs into different stages. Jobs of the same `stage`
are executed in `parallel`. For more info about the use of `stage` please check
[stages](#stages).

### only and except

`only` and `except` are two parameters that set a job policy to limit when
jobs are created:

1. `only` defines the names of branches and tags for which the job will run.
2. `except` defines the names of branches and tags for which the job will
    **not** run.

There are a few rules that apply to the usage of job policy:

* `only` and `except` are inclusive. If both `only` and `except` are defined
   in a job specification, the ref is filtered by `only` and `except` and needs
   to pass both filters to be created.
* `only` and `except` allow the use of regular expressions. Regex don't need to
  be escaped using `/` at the beginning and end, e.g. you should write `issue-.*$`
  instead of `/issue-.*$/`. 

In addition, `only` and `except` allow the use of special keywords:

| **Value** |  **Description**  |
| --------- |  ---------------- |
| `branches`  | When a branch is pushed.  |
| `tags`      | When a tag is pushed.  |
| `forks`     | For pipelines created when a pull request is created from a fork. |
| `web`       | For pipelines created using **Run pipeline** button in AlloyCI's UI (**not implemented yet**). |

In the example below, `job` will run only for refs that have `issue-` in them,
whereas all other branches will be skipped:

```yaml
---
job:
  only:
  - issue-.*$
  except:
  - branches

```

In this example, `job` will run only for refs that are tagged, or if the pipeline was created from
a fork.

```yaml
---
job:
  only:
  - tags
  - forks

```

In this example `job` will run for all branches, except the ones named `master`, or `develop`:

```yaml
---
job:
  except:
  - master
  - develop
```

### Job variables

It is possible to define job variables using a `variables` keyword on a job
level. It works basically the same way as its [global-level equivalent](#variables),
but allows you to define job-specific variables.

When the `variables` keyword is used on a job level, it overrides the global YAML
job variables and predefined ones. To turn off global defined variables
in your job, define an empty array:

```yaml
---
job_name:
  variables: []
```

Job variables priority is defined in the [variables documentation][variables].

### tags

`tags` is used to select specific Runners from the list of all Runners that are
allowed to run this project.

During the registration of a Runner, you can specify the Runner's tags, for
example `ruby`, `postgres`, `development`.

`tags` allow you to run jobs with Runners that have the specified tags
assigned to them:

```yaml
---
job:
  tags:
  - ruby
  - postgres

```

The specification above, will make sure that `job` is built by a Runner that
has both `ruby` AND `postgres` tags defined. If a pipeline job has tags defined,
but there are no runners registered with these tags, the job will not be picked
up and it will remain in a `pending` state indefinitely.

This parameter must be an array, even if it only contains a single tag.

### allow_failure

`allow_failure` is used when you want to allow a job to fail without impacting
the rest of the CI suite. Failed jobs don't contribute to the commit status.

When enabled and the job fails, the pipeline will be successful/green for all
intents and purposes, but a "CI build passed with warnings" message  will be
displayed on the merge request or commit or job page. This is to be used by
jobs that are allowed to fail, but where failure indicates some other (manual)
steps should be taken elsewhere.

In the example below, `job1` and `job2` will run in parallel, but if `job1`
fails, it will not stop the next stage from running, since it's marked with
`"allow_failure": true`:

```yaml
---
job1:
  stage: test
  script:
  - execute_script_that_will_fail
  allow_failure: true
job2:
  stage: test
  script:
  - execute_script_that_will_succeed
job3:
  stage: deploy
  script:
  - deploy_to_staging

```

### when

`when` is used to implement jobs that are run in case of failure or despite the
failure.

`when` can be set to one of the following values:

1. `on_success` - execute job only when all jobs from prior stages
    succeed. This is the default.
1. `on_failure` - execute job only when at least one job from prior stages
    fails.
1. `always` - execute job regardless of the status of jobs from prior stages.

For example:

```yaml
---
stages:
- build
- cleanup_build
- test
- deploy
- cleanup

build_job:
  stage: build
  script:
  - make build

cleanup_build_job:
  stage: cleanup_build
  script:
  - cleanup build when failed
  when: on_failure

test_job:
  stage: test
  script:
  - make test

cleanup_job:
  stage: cleanup
  script:
  - cleanup after jobs
  when: always
```

The above script will:

1. Execute `cleanup_build_job` only when `build_job` fails.
2. Always execute `cleanup_job` as the last step in pipeline regardless of
   success or failure.

### artifacts

>
**Notes:**
- Currently not all executors are supported.
- Job artifacts are only collected for successful jobs by default.

`artifacts` is used to specify a list of files and directories which should be
attached to the job after success. You can only use paths that are within the
project workspace. To pass artifacts between different jobs, see [dependencies](#dependencies).
Below are some examples.

Send all files in `binaries` and `.config`:

```yaml
---
artifacts:
  paths:
  - binaries/
  - ".config"
```

Send all Git untracked files:

```yaml
---
artifacts:
  untracked: true
```

Send all Git untracked files and files in `binaries`:

```yaml
---
artifacts:
  untracked: 'true'
  paths:
  - binaries/

```

To disable artifact passing, define the job with empty [dependencies](#dependencies):

```yaml
---
job:
  stage: build
  script: make build
  dependencies: []

```

You may want to create artifacts only for tagged releases to avoid filling the
build server storage with temporary build artifacts.

Create artifacts only for tags (`default-job` will not create artifacts):

```yaml
---
default-job:
  script:
  - mvn test -U
  except:
  - tags
release-job:
  script:
  - mvn package -U
  artifacts:
    paths:
    - target/*.war
  only:
  - tags
```

The artifacts will be sent to AlloyCI after the job finishes successfully and will
be available for download in the AlloyCI UI.

#### artifacts:name

> Introduced in GitLab 8.6 and GitLab Runner v1.1.0.

The `name` directive allows you to define the name of the created artifacts
archive. That way, you can have a unique name for every archive which could be
useful when you'd like to download the archive from GitLab. The `artifacts:name`
variable can make use of any of the [predefined variables](../variables/README.md).
The default name is `artifacts`, which becomes `artifacts.zip` when downloaded.

---

**Example configurations**

To create an archive with a name of the current job:

```yaml
---
job:
  artifacts:
    name: "$CI_JOB_NAME"

```

To create an archive with a name of the current branch or tag including only
the files that are untracked by Git:

```yaml
---
job:
  artifacts:
    name: "$CI_COMMIT_REF_NAME"
    untracked: true

```

To create an archive with a name of the current job and the current branch or
tag including only the files that are untracked by Git:

```yaml
---
job:
  artifacts:
    name: "${CI_JOB_NAME}_${CI_COMMIT_REF_NAME}"
    untracked: true

```

To create an archive with a name of the current [stage](#stages) and branch name:

```yaml
---
job:
  artifacts:
    name: "${CI_JOB_STAGE}_${CI_COMMIT_REF_NAME}"
    untracked: true

```

---

If you use **Windows Batch** to run your shell scripts you need to replace
`$` with `%`:

```yaml
---
job:
  artifacts:
    name: "%CI_JOB_STAGE%_%CI_COMMIT_REF_NAME%"
    untracked: true

```

If you use **Windows PowerShell** to run your shell scripts you need to replace
`$` with `$env:`:

```yaml
job:
  artifacts:
    name: "$env:CI_JOB_STAGE_$env:CI_COMMIT_REF_NAME"
    untracked: true

```


#### artifacts:when

`artifacts:when` is used to upload artifacts on job failure or despite the
failure.

`artifacts:when` can be set to one of the following values:

1. `on_success` - upload artifacts only when the job succeeds. This is the default.
1. `on_failure` - upload artifacts only when the job fails.
1. `always` - upload artifacts regardless of the job status.

---

**Example configurations**

To upload artifacts only when job fails.

```yaml
job:
  artifacts:
    when: on_failure
```

#### artifacts:expire_in

`artifacts:expire_in` is used to delete uploaded artifacts after the specified
time. By default, artifacts are stored on GitLab forever. `expire_in` allows you
to specify how long artifacts should live before they expire, counting from the
time they are uploaded and stored on GitLab.

You can use the **Keep** button on the build page to override expiration and
keep artifacts forever.

After expiry, artifacts are actually deleted hourly by default (via a cron job),
but they are not accessible after expiry.

The value of `expire_in` is an elapsed time. Examples of parseable values:

- '3 mins 4 sec'
- '2 hrs 20 min'
- '2h20min'
- '6 mos 1 day'
- '47 yrs 6 mos 4d'
- '3 weeks 2 days'

Using commas, dots, colons, or any other character is not allowed, only integers
and abbreviations of time units.

---

**Example configurations**

To expire artifacts 1 week after being uploaded:

```yaml
job:
  artifacts:
    expire_in: 1 week
```

### dependencies

This feature should be used in conjunction with [`artifacts`](#artifacts) and
allows you to define the artifacts to pass between different jobs.

Note that `artifacts` from all previous [stages](#stages) are passed by default.

To use this feature, define `dependencies` in context of the job and pass
a list of all previous jobs from which the artifacts should be downloaded.
You can only define jobs from stages that are executed before the current one.
An error will be shown if you define jobs from the current stage or next ones.
Defining an empty array will skip downloading any artifacts for that job.
The status of the previous job is not considered when using `dependencies`, so
if it failed or it is a manual job that was not run, no error occurs.

---

In the following example, we define two jobs with artifacts, `build:osx` and
`build:linux`. When the `test:osx` is executed, the artifacts from `build:osx`
will be downloaded and extracted in the context of the build. The same happens
for `test:linux` and artifacts from `build:linux`.

The job `deploy` will download artifacts from all previous jobs because of
the [stage](#stages) precedence:

```yaml
build:osx:
  stage: build
  script: make build:osx
  artifacts:
    paths:
    - binaries/

build:linux:
  stage: build
  script: make build:linux
  artifacts:
    paths:
    - binaries/

test:osx:
  stage: test
  script: make test:osx
  dependencies:
  - build:osx

test:linux:
  stage: test
  script: make test:linux
  dependencies:
  - build:linux

deploy:
  stage: deploy
  script: make deploy
```

#### When a dependent job will fail

If the artifacts of the job that is set as a dependency have been
[expired](#artifacts-expire_in) the dependent job will fail.

### before_script and after_script

It's possible to overwrite the globally defined `before_script` and `after_script`:

```yaml
before_script:
- global before script
job:
  before_script:
  - execute this instead of global before script
  script:
  - my command
  after_script:
  - execute this after my script

```

## Git Strategy

> Experimental feature.  May change or be removed completely in future releases.

You can set the `GIT_STRATEGY` used for getting recent application code, either
in the global [`variables`](#variables) section or the [`variables`](#job-variables)
section for individual jobs. If left unspecified, the default from project
settings will be used.

There are three possible values: `clone`, `fetch`, and `none`.

`clone` is the slowest option. It clones the repository from scratch for every
job, ensuring that the project workspace is always pristine.

```yaml
variables:
  GIT_STRATEGY: clone
```

`fetch` is faster as it re-uses the project workspace (falling back to `clone`
if it doesn't exist). `git clean` is used to undo any changes made by the last
job, and `git fetch` is used to retrieve commits made since the last job ran.

```yaml
variables:
  GIT_STRATEGY: fetch
```

`none` also re-uses the project workspace, but skips all Git operations
(including GitLab Runner's pre-clone script, if present). It is mostly useful
for jobs that operate exclusively on artifacts (e.g., `deploy`). Git repository
data may be present, but it is certain to be out of date, so you should only
rely on files brought into the project workspace from cache or artifacts.

```yaml
variables:
  GIT_STRATEGY: none
}
```

**Note:** If you'd like for jobs to be processed when a pull request is created 
from a fork, then you _need_ to the `fetch` strategy (default) for jobs that rely
on the repository.

## Git Checkout

The `GIT_CHECKOUT` variable can be used when the `GIT_STRATEGY` is set to either
`clone` or `fetch` to specify whether a `git checkout` should be run. If not
specified, it defaults to true. Like `GIT_STRATEGY`, it can be set in either the
global [`variables`](#variables) section or the [`variables`](#job-variables)
section for individual jobs.

If set to `false`, the Runner will:

- when doing `fetch` - update the repository and leave working copy on
  the current revision,
- when doing `clone` - clone the repository and leave working copy on the
  default branch.

Having this setting set to `true` will mean that for both `clone` and `fetch`
strategies the Runner will checkout the working copy to a revision related
to the CI pipeline:

```yaml
variables:
  GIT_STRATEGY: clone
  GIT_CHECKOUT: 'false'
script:
- git checkout master
- git merge $CI_COMMIT_REF_NAME
```

## Git Submodule Strategy

The `GIT_SUBMODULE_STRATEGY` variable is used to control if / how Git
submodules are included when fetching the code before a build. Like
`GIT_STRATEGY`, it can be set in either the global [`variables`](#variables)
section or the [`variables`](#job-variables) section for individual jobs.

There are three possible values: `none`, `normal`, and `recursive`:

- `none` means that submodules will not be included when fetching the project
  code. This is the default, which matches the pre-v1.10 behavior.

- `normal` means that only the top-level submodules will be included. It is
  equivalent to:

    ```
    git submodule sync
    git submodule update --init
    ```

- `recursive` means that all submodules (including submodules of submodules)
  will be included. It is equivalent to:

    ```
    git submodule sync --recursive
    git submodule update --init --recursive
    ```

Note that for this feature to work correctly, the submodules must be configured
(in `.gitmodules`) with the HTTP(S) URL of a publicly-accessible repository.

```yaml
{
  "variables": {
    "GIT_SUBMODULE_STRATEGY": "recursive"
  }
}
```  


## Job stages attempts

You can set the number for attempts the running job will try to execute each
of the following stages:

| Variable                        | Description |
|-------------------------------- |-------------|
| **GET_SOURCES_ATTEMPTS**        | Number of attempts to fetch sources running a job |
| **ARTIFACT_DOWNLOAD_ATTEMPTS**  | Number of attempts to download artifacts running a job |
| **RESTORE_CACHE_ATTEMPTS**      | Number of attempts to restore the cache running a job |

The default is one single attempt.

Example:

```yaml
{
  "variables": {
    "GET_SOURCES_ATTEMPTS": "3"
  }
}
```

You can set them in the global [`variables`](#variables) section or the
[`variables`](#job-variables) section for individual jobs.

## Shallow cloning

> Experimental feature. May change in future releases or be removed completely.

You can specify the depth of fetching and cloning using `GIT_DEPTH`. This allows
shallow cloning of the repository which can significantly speed up cloning for
repositories with a large number of commits or old, large binaries. The value is
passed to `git fetch` and `git clone`.

>**Note:**
If you use a depth of 1 and have a queue of jobs or retry
jobs, jobs may fail.

Since Git fetching and cloning is based on a ref, such as a branch name, Runners
can't clone a specific commit SHA. If there are multiple jobs in the queue, or
you are retrying an old job, the commit to be tested needs to be within the
Git history that is cloned. Setting too small a value for `GIT_DEPTH` can make
it impossible to run these old commits. You will see `unresolved reference` in
job logs. You should then reconsider changing `GIT_DEPTH` to a higher value.

Jobs that rely on `git describe` may not work correctly when `GIT_DEPTH` is
set since only part of the Git history is present.

To fetch or clone only the last 3 commits:

```yaml
{
  "variables": {
    "GIT_DEPTH": "3"
  }
}
```
## Validate the .alloy-ci.yml file (**NOT IMPLEMENTED YET**)

Each instance of AlloyCI has an embedded debug tool called Lint.
You can find the link under `/lint` of your AlloyCI instance.

## Using reserved keywords

If you get validation error when using specific values (e.g., `true` or `false`),
try to quote them, or change them to a different form (e.g., `/bin/true`).

## Skipping jobs

If your commit message contains `[ci skip]` or `[skip ci]`, using any
capitalization, the pipeline and jobs will not be created.

## Examples

Visit the [examples README][examples] to see a list of examples using AlloyCI
with various languages.

[examples]: ../examples/README.md
[variables]: ../variables/README.md
