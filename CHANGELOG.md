<a name="v0.7.0"></a>
### v0.7.0 (2018-05-07)

#### Features


#### Bug Fixes

* Fixed redirect loop that would happen when an authentication token expires.

#### Deprecations

* **MAJOR DEPRECATION** JSON config files for build/pipeline configuration are no longer supported. Use YAML files instead.
  The main reason behind this decision is that YAML is much more flexible than JSON. It allows us to use aliases in oder to avoid
  duplication, to add comments to make the config file more understandable, and it is the de facto standard configuration file
  for almost all CI systems in the market.
 

<a name="v0.6.0"></a>
### v0.6.0 (2018-05-07)

#### Features

* Added support for S3 compatible object storage to store build artifacts. See the [documentation](doc/README.md#configuration)
  for instructions on how to set it up. Most S3 compatible services, like AWS S3, Digital Ocean Spaces, Minio, etc. should work.
* Improved runner ENV variables for better Coveralls support

#### Bug Fixes

* Fixed small bug on the `ArtifactSweeper` GenServer. The server state was not being returned, which caused
  intermittent errors on subsequent runs (one would work, the next one would error out, the next one would work, etc.)
* Properly populate the `$CI_COMMIT_REF_SLUG` environment variable with the shorthand for the branch/tag name

#### Chores

* Updated dependencies
* Cleaned up data structures code
  - Replaced use of `use AlloyCi.Web :schema` with proper `Ecto` imports  

<a name="v0.5.0"></a>
### v0.5.0 (2018-03-30)

#### Features

* Added support for GitHub Enterprise
  - AlloyCI can now be used with a GitHub Enterprise installation. See the [documentation](doc/github_enterprise.md) for more info on how to set it up.
* Ditched core-ui in favor of a cleaner, more functional design that is more appealing to the eye
* Expired artifacts are now pruned once a day (interval can be configured)
* Artifacts can be kept forever, by clicking a button in the build page
* Build artifacts can now be downloaded from the build page
  - For this, the build page was completely reworked
  - It is now its own page with valuable information about the build, along the build trace and artifacts that may have been created
* Individual builds can now be restarted independently (build will be copied, and old data will be kept)

#### Bug Fixes

* When cancelling a pipeline, all builds were marked as cancelled, now only builds that are either
  `created`, `running`, or `pending` are updated.
* After the upgrade to Guardian 1.0 it became impossible to add another authentication method to an
  existing user. This has been fixed.  

<a name="v0.4.0"></a>
### v0.4.0 (2018-03-08)

#### Features

* Show available global runners on the project's settings page
* Initial support for build artifacts:
  - Jobs can create artifacts and upload them to the server (only local storage supported for now)
  - Jobs can download artifacts from previous builds, if they depend on them
* Support for dependent builds:
  - Builds with artifacts from previous stages will be automatically added as dependencies for jobs of the subsequent stage
  - Builds can explicitly declare their own dependencies via the `.alloy-ci.json` file
* Added the option to use Sentry for error catching in production
* Updated Guardian to 1.0  

#### Bug Fixes

* Redirect to main projects if user is logged in and visits the register page
* Skip updating the build trace, if the runner calls the endpoint with an empty string
* Updated JS dependencies

<a name="v0.3.0"></a>
### v0.3.0 (2018-02-16)

#### Features

* Pipelines are now created when a pull request from a fork is submitted.
  This feature requires the newly released [AlloyCI Runner](https://github.com/AlloyCI/alloy-runner) (GitLab Runner fork),
  so it is incompatible with all previous and future GitLab Runner versions. (#29)
* Added support for `only` and `except` keywords for build jobs. This gives
  you better control over which jobs run when. (#14)
* Regular users can now manage project specific runners for projects to which
  they have access. (#33)
* Projects now support the use of secret variables. They can be used to pass
  sensitive information to the runner without committing it to the repository. (#23)

#### Bug Fixes

* Redirect to the main projects' view when all auth options have already 
  been created. (#30)
* Better processing of pipelines when the worker is called (5a9ca8f)
* Fix notification bug, that would send one on every failed build. (63dc787)

<a name="v0.2.0"></a>
### v0.2.0 (2017-10-16)

#### Breaking changes

* All mentions of `integration` in the documentation, code, and configuration
  files have been replaced with `app`. This is to conform with the changes imposed
  by GitHub and their API. (#28)

<a name="v0.1.0"></a>
### v0.1.0 (2017-09-13)

#### Features

* First public release
