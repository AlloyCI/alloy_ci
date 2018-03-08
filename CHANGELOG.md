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
