# Variables

When receiving a job from Alloy CI, the [Runner] prepares the build environment.
It starts by setting a list of **predefined variables** (environment variables)
and a list of **user-defined variables**.

## Priority of variables

The variables can be overwritten and they take precedence over each other in
this order:

1. [Secret variables](#secret-variables)
1. YAML-defined [job-level variables](../yaml/README.md#job-variables)
1. YAML-defined [global variables](../yaml/README.md#variables)

For example, if you define `API_TOKEN=secure` as a secret variable and
`API_TOKEN=plain` in your `.alloy-ci.yml`, the `API_TOKEN` will take the value
`secure` as the secret variables are higher in the chain.

## Predefined variables (Environment variables)

Some of the predefined environment variables are available only if a minimum
version of the Runner is used. Consult the table below to find the
version of Runner required.

| Variable                        | Runner | Description |
|-------------------------------- |--------|-------------|
| **ALLOY_CI**                    | all    | Mark that job is executed in Alloy CI environment |
| **CI**                          | 0.4    | Mark that job is executed in CI environment |
| **CI_COMMIT_REF_NAME**          | all    | The branch or tag name for which project is built |
| **CI_COMMIT_SHA**               | all    | The commit revision for which project is built |
| **CI_COMMIT_MESSAGE**           | all    | The message of the HEAD commit |
| **CI_COMMIT_PUSHER**            | all    | Email of the user that pushed the commits |
| **CI_DEBUG_TRACE**              | 1.7    | Whether [debug tracing](#debug-tracing) is enabled |
| **CI_ENVIRONMENT_NAME**         | all    | The name of the environment for this job |
| **CI_JOB_ID**                   | all    | The unique id of the current job that Alloy CI uses internally |
| **CI_JOB_MANUAL**               | all    | The flag to indicate that job was manually started |
| **CI_JOB_NAME**                 | 0.5    | The name of the job as defined in `.alloy-ci.yml` |
| **CI_JOB_STAGE**                | 0.5    | The name of the stage as defined in `.alloy-ci.yml` |
| **CI_JOB_TOKEN**                | 1.2    | Token used for authenticating with the Alloy Container Registry |
| **CI_REPOSITORY_URL**           | all    | The URL to clone the Git repository |
| **CI_RUNNER_ID**                | 0.5    | The unique id of runner being used |
| **CI_RUNNER_TAGS**              | 0.5    | The defined runner tags |
| **CI_PIPELINE_ID**              | 0.5    | The unique id of the current pipeline that AlloyCI uses internally |
| **CI_PROJECT_DIR**              | all    | The full path where the repository is cloned and where the job is run |
| **CI_PROJECT_NAME**             | 0.5    | The project name that is currently being built |
| **CI_SERVER**                   | all    | Mark that job is executed in CI environment |
| **CI_SERVER_NAME**              | all    | The name of CI server that is used to coordinate jobs |
| **CI_SERVER_VERSION**           | all    | AlloyCI version that is used to schedule jobs |
| **ARTIFACT_DOWNLOAD_ATTEMPTS**  | 1.9    | Number of attempts to download artifacts running a job |
| **GET_SOURCES_ATTEMPTS**        | 1.9    | Number of attempts to fetch sources running a job |
| **RESTORE_CACHE_ATTEMPTS**      | 1.9    | Number of attempts to restore the cache running a job |


## `.alloy-ci.yml` defined variables

Alloy CI allows you to add to `.alloy-ci.yml` variables that are set in the
build environment. The variables are hence saved in the repository, and they
are meant to store non-sensitive project configuration, e.g., `RAILS_ENV` or
`DATABASE_URL`.

For example, if you set the variable below globally (not inside a job), it will
be used in all executed commands and scripts:

```yaml
---
variables:
  DATABASE_URL: postgres://postgres@postgres/my_database
```

The YAML-defined variables are also set to all created
[service containers](../docker/using_docker_images.md), thus allowing to fine
tune them.

Variables can be defined at a global level, but also at a job level. To turn off
global defined variables in your job, define an empty array:

```yaml
---
job_name:
  variables: []
```

You are able to use other variables inside your variable definition (or escape them with `$$`):

```yaml
---
variables:
  LS_CMD: ls $FLAGS $$TMP_DIR
  FLAGS: "-al"
script:
- eval $LS_CMD
```

## Secret variables

>**Notes:**
- Be aware that secret variables are not masked, and their values can be shown
  in the job logs if explicitly asked to do so.

AlloyCI allows you to define per-project **secret variables** that are set in
the build environment. The secret variables are stored out of the repository
(`.alloy-ci.yml`) and are securely passed to the Runner making them
available in the build environment. It's the recommended method to use for
storing things like passwords, secret keys and credentials.

Secret variables can be added by going to your project's
**Settings**, then finding the section called
**Secret Variables**. The variables are stored in a YAML compatible format, so
an example for inputting the variables is:

```yaml
---
SUPER_SECRET: Bruce Wayne is Batman
SECRET_PASSWORD: Alfred
```

Once you set them, they will be available for all subsequent jobs.

## Debug tracing

>
> **WARNING:** Enabling debug tracing can have severe security implications. The
  output **will** contain the content of all your secret variables and any other
  secrets! The output **will** be uploaded to the AlloyCI server and made visible
  in job traces!

By default, the Runner hides most of the details of what it is doing when
processing a job. This behavior keeps job traces short, and prevents secrets
from being leaked into the trace unless your script writes them to the screen.

If a job isn't working as expected, this can make the problem difficult to
investigate; in these cases, you can enable debug tracing in `.alloy-ci.yml`.
This feature enables the shell's execution
trace, resulting in a verbose job trace listing all commands that were run,
variables that were set, etc.

To enable debug traces, set the `CI_DEBUG_TRACE` variable to `true`:

```yaml
---
job_name:
  variables:
    CI_DEBUG_TRACE: true
```

[runner]: ../runners/README.md
[triggered]: ../triggers/README.md
