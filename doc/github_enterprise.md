# Using AlloyCI with GitHub Enterprise

GitHub Enterprise v2.13 introduced support for GitHub Apps, which means that AlloyCI,
as of v0.5.0, is now compatible with GitHub Enterprise as well.

## GitHub Apps

In order to use your own instance of AlloyCI with GitHub Enterprise, you will need to
register a new GitHub App. Go to https://developer.github.com/enterprise/apps/building-github-apps/creating-a-github-app/
for a detailed guide on how to get started.

Once you have reached the **New GitHub App** page (https://github.example.com/settings/apps/new), fill in the form with your data, 
and the following for the specified fields:

- `User authorization callback URL:` => https://alloy-ci.example.com/auth/github/callback
- `Webhook URL:` => https://alloy-ci.example.com/api/github/handle_event
- `Webhook secret (optional):` => A random string of characters

Under permissions, make sure that the following permissions are enabled and with
the correct settings:

**Commit Statuses:**

- Read & Write

**Repository Contents:**

- Read & Write

**Subscribe to events**

Select the following checkboxes:

- [x] Status
- [x] Create
- [x] Push
- [x] Delete

---

Finally, select where the integration can be installed.

Once created, you will have almost everything you need to setup the environment
variables for AlloyCI. GitHub will redirect you to your newly created app.

On this page, GitHub will ask you to generate a private key for your installation.
Do so, and save the generated file. The contents of this file will be used for the
`GITHUB_PRIVATE_KEY` environment variable. Don't lose this file, or you will have
to generate a new key.

The `GITHUB_APP_ID` appears in the `About` section, right at the end.

The `GITHUB_APP_URL` will be the public link to your app.

The Webhook secret you selected before will go to the `GITHUB_SECRET_TOKEN` variable.

**Important:** On this page you will also find some OAuth credentials. Unfortunately,
due to a bug in GitHub's OAuth system, we cannot use these credentials for the
`GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET` variables. We will need to create
a new OAuth application in order to allow users to sign up via GitHub.

If you prefer your users to **manually create an account**, and then link that
account to their GitHub accounts, you can use these credentials and skip the next
step.

## GitHub OAuth App

As mentioned before, if you'd like your users to create accounts via GitHub, you
will need to also create a separate OAuth app. To do so, go to
https://github.example.com/settings/applications/new

Fill in the form with your information, and as `Authorization callback URL`
use `https://alloy-ci.example.com/auth/github/callback`.

Once the app is created, you will be redirected to a page containing the client ID
and secret needed for the `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET` variables.

Once you have values for all the `GITHUB_*` variables, you can continue with the
next steps.

## Next steps

Head over to the [requirements](README.md#requirements) section of the main installation
documentation for the next steps.

Don't forget to set the `GITHUB_ENTERPRISE` environment variable to `true`, and 
`GITHUB_ENDPOINT` to the URL of your GitHub Enterprise installation.
