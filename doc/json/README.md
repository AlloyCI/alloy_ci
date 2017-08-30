# Configuration of your jobs with .alloy-ci.json

This document describes the usage of `.alloy-ci.json`, the file that is used to
tell GitLab Runner how to manage your project's jobs.

If you want a quick introduction to AlloyCI, follow our
[quick start guide](../quick_start/README.md).

## .alloy-ci.json

AlloyCI uses a [JSON](https://en.wikipedia.org/wiki/JSON)
file (`.alloy-ci.json`) for the project configuration. It is placed in the root
of your repository and contains definitions of how your project should be built.

The JSON file defines a set of jobs with constraints stating when they should
be run. The jobs are defined as top-level elements with a name and always have
to contain at least the `script` clause:

```json
{
  "job1": {
    "script": ["execute-script-for-job1"]    
  },
  "job2": {
    "script": ["execute-script-for-job2"]    
  }
}
```

The above example is the simplest possible CI configuration with two separate
jobs, where each of the jobs executes a different command.

Of course a command can execute code directly (`./configure;make;make install`)
or run a script (`test.sh`) in the repository.

Jobs are picked up by [Runners](../runners/README.md) and executed within the
environment of the Runner. What is important, is that each job is run
independently from each other.

The JSON syntax allows for using more complex job specifications than in the
above example:

```json
{
  "image": "elixir:latest",
  "services": [
    "postgres"
  ],
  "before_script": [
    "mix deps.get"
  ],
  "after_script": [
    "rm secrets"
  ],
  "stages": [
    "build",
    "test",
    "deploy"
  ],
  "job1": {
    "stage": "build",
    "script": ["execute-script-for-job1"],
    "tags": ["docker"]   
  }
}
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
jobs. This has to be an array.

### stages

`stages` is used to define stages that can be used by jobs.
The specification of `stages` allows for having flexible multi stage pipelines.

The ordering of elements in `stages` defines the ordering of jobs' execution:

1. Jobs of the same stage are run in parallel.
1. Jobs of the next stage are run after the jobs from the previous stage
   complete successfully.

Let's consider the following example, which defines 3 stages:

```json
{
  "stages": [
    "build",
    "test",
    "deploy"
  ]
}
```

1. First, all jobs of `build` are executed in parallel.
1. If all jobs of `build` succeed, the `test` jobs are executed in parallel.
1. If all jobs of `test` succeed, the `deploy` jobs are executed in parallel.
1. If all jobs of `deploy` succeed, the commit is marked as `success`.
1. If any of the previous jobs fails, the commit is marked as `failed` and no
   jobs of further stage are executed.

There are also two edge cases worth mentioning:

1. If no `stages` are defined in `.alloy-ci.json`, then the `build`,
   `test` and `deploy` are allowed to be used as job's stage by default.
2. If a job doesn't specify a `stage`, the job is assigned the `test` stage.

### variables

AlloyCI allows you to add variables to `.alloy-ci.json` that are set in the
job environment. The variables are stored in the Git repository and are meant
to store non-sensitive project configuration, for example:

```json
{
  "variables": {
    "DATABASE_URL": "postgres://postgres@postgres/my_database"
  }
}
```

These variables can be later used in all executed commands and scripts.
The JSON-defined variables are also set to all created service containers,
thus allowing to fine tune them. Variables can be also defined on a
[job level](#job-variables).

Except for the user defined variables, there are also the ones set up by the
Runner itself. One example would be `CI_COMMIT_REF_NAME` which has the value of
the branch or tag name for which project is built.

[Learn more about variables.][variables]

### cache

> Introduced in GitLab Runner v0.7.0.

`cache` is used to specify a list of files and directories which should be
cached between jobs. You can only use paths that are within the project
workspace.

If `cache` is defined outside the scope of jobs, it means it is set
globally and all jobs will use that definition.

Cache all files in `binaries` and `.config`:

```json
{
  "rspec": {
    "script": ["test"],
    "cache": {
      "paths": [
        "binaries/",
        ".config"
      ]
    }
  }
}
```

Cache all Git untracked files:

```json
{
  "rspec": {
    "script": ["test"],
    "cache": {
      "untracked": "true"
    }
  }
}
```

Cache all Git untracked files and files in `binaries`:

```json
{
  "rspec": {
    "script": ["test"],
    "cache": {
      "untracked": "true",
      "paths": [
        "binaries/"
      ]
    }
  }
}
```

Locally defined cache overrides globally defined options. The following `rspec`
job will cache only `binaries/`:

```json
{
  "cache": {
    "paths": ["my/files"]
  },

  "rspec": {
    "script": ["test"],
    "cache": {
      "paths": [
        "binaries/"
      ]
    }
  }
}
```

Note that since cache is shared between jobs cache content can be overwritten.

The cache is provided on a best-effort basis, so don't expect that the cache
will be always present. For implementation details, please check GitLab Runner.

## Jobs

`.alloy-ci.json` allows you to specify an unlimited number of jobs. Each job
must have a unique name, which is not one of the keywords mentioned above.
A job is defined by a list of parameters that define the job behavior.

```json
{
  "job_name": {
    "script": [
      "rake spec",
      "coverage"
    ],
    "stage": "test",
    "only": [
      "master"
    ],
    "except": [
      "develop"
    ],
    "tags": [
      "ruby",
      "postgres"
    ],
    "allow_failure": true
  }
}
```

| Keyword       | Required | Description | Type |
|---------------|----------|-------------|------|
| script        | yes      | Defines a shell script which is executed by Runner | String |
| image         | no       | Use docker image, covered in [Using Docker Images](../docker/README.md) | String or JSON Object |
| services      | no       | Use docker services, covered in [Using Docker Images](../docker/README.md) | Array of: Strings or JSON Objects  |
| stage         | no       | Defines a job stage (default: `test`) | String |
| variables     | no       | Define job variables on a job level | JSON Object |
| tags          | no       | Defines a list of tags which are used to select Runner | Array |
| allow_failure | no       | Allow job to fail. Failed job doesn't contribute to commit status | Boolean |
| when          | no       | Define when to run job. Can be `on_success`, `on_failure`, `always` or `manual` | String |
| cache         | no       | Define list of files that should be cached between subsequent runs | JSON Object |
| before_script | no       | Override a set of commands that are executed before job | Array |
| after_script  | no       | Override a set of commands that are executed after job | Array |

### script

`script` is a shell script which is executed by the Runner. For example:

```json
{
  "job": {
    "script": ["bundle exec rspec"]
  }
}  
```

This parameter must be an array, even if it only contains a single command.


### stage

`stage` allows to group jobs into different stages. Jobs of the same `stage`
are executed in `parallel`. For more info about the use of `stage` please check
[stages](#stages).

### Job variables

It is possible to define job variables using a `variables` keyword on a job
level. It works basically the same way as its [global-level equivalent](#variables),
but allows you to define job-specific variables.

When the `variables` keyword is used on a job level, it overrides the global JSON
job variables and predefined ones. To turn off global defined variables
in your job, define an empty array:

```json
{
  "job_name": {
    "variables": {}
  }
}
```

Job variables priority is defined in the [variables documentation][variables].

### tags

`tags` is used to select specific Runners from the list of all Runners that are
allowed to run this project.

During the registration of a Runner, you can specify the Runner's tags, for
example `ruby`, `postgres`, `development`.

`tags` allow you to run jobs with Runners that have the specified tags
assigned to them:

```json
{
  "job": {
    "tags": [
      "ruby",
      "postgres"
    ]
  }
}
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

```json
{
  "job1": {
    "stage": "test",
    "script": [
      "execute_script_that_will_fail"
    ],
    "allow_failure": true
  },
  "job2": {
    "stage": "test",
    "script": [
      "execute_script_that_will_succeed"
    ]
  },
  "job3": {
    "stage": "deploy",
    "script": [
      "deploy_to_staging"
    ]
  }
}
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

```json
{
  "stages": [
    "build",
    "cleanup_build",
    "test",
    "deploy",
    "cleanup"
  ],
  "build_job": {
    "stage": "build",
    "script": [
      "make build"
    ]
  },
  "cleanup_build_job": {
    "stage": "cleanup_build",
    "script": [
      "cleanup build when failed"
    ],
    "when": "on_failure"
  },
  "test_job": {
    "stage": "test",
    "script": [
      "make test"
    ]
  },
  "cleanup_job": {
    "stage": "cleanup",
    "script": [
      "cleanup after jobs"
    ],
    "when": "always"
  }
}
```

The above script will:

1. Execute `cleanup_build_job` only when `build_job` fails.
2. Always execute `cleanup_job` as the last step in pipeline regardless of
   success or failure.


### before_script and after_script

It's possible to overwrite the globally defined `before_script` and `after_script`:

```json
{
  "before_script": [
    "global before script"
  ],
  "job": {
    "before_script": [
      "execute this instead of global before script"
    ],
    "script": [
      "my command"
    ],
    "after_script": [
      "execute this after my script"
    ]
  }
}
```

## Git Submodule Strategy

> Requires GitLab Runner v1.10+.

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

```json
{
  "variables": {
    "GIT_SUBMODULE_STRATEGY": "recursive"
  }
}
```  


## Job stages attempts

> Requires GitLab Runner v1.9+.

You can set the number for attempts the running job will try to execute each
of the following stages:

| Variable                        | Description |
|-------------------------------- |-------------|
| **GET_SOURCES_ATTEMPTS**        | Number of attempts to fetch sources running a job |
| **ARTIFACT_DOWNLOAD_ATTEMPTS**  | Number of attempts to download artifacts running a job |
| **RESTORE_CACHE_ATTEMPTS**      | Number of attempts to restore the cache running a job |

The default is one single attempt.

Example:

```json
{
  "variables": {
    "GET_SOURCES_ATTEMPTS": "3"
  }
}
```

You can set them in the global [`variables`](#variables) section or the
[`variables`](#job-variables) section for individual jobs.

## Validate the .alloy-ci.json

**NOT IMPLEMENTED YET**

Each instance of AlloyCI has an embedded debug tool called Lint.
You can find the link under `/lint` of your AlloyCI instance.

## Skipping jobs

If your commit message contains `[ci skip]` or `[skip ci]`, using any
capitalization, the pipeline and jobs will not be created.

## Examples

Visit the [examples README][examples] to see a list of examples using AlloyCI
with various languages.

[examples]: ../examples/README.md
[variables]: ../variables/README.md
