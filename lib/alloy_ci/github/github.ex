defmodule AlloyCi.Github do
  @moduledoc """
  Defines the behaviour for interacting with the GitHub API. There is a production
  implementation, and a test implementation of this behaviour.
  """
  alias AlloyCi.{Pipeline, Project}

  @callback alloy_ci_config(project :: Project.t(), pipeline :: Pipeline.t()) :: map()

  @callback app_client() :: any

  @callback clone_url(project :: Project.t(), pipeline :: Pipeline.t()) :: binary()

  @callback commit(project :: Project.t(), sha :: binary(), installation_id :: pos_integer()) ::
              map()

  @callback fetch_repos(token :: binary()) :: any()

  @callback installation_id_for(github_uid :: binary()) :: pos_integer()

  @callback notify_cancelled!(project :: Project.t(), pipeline :: Pipeline.t()) :: any()

  @callback notify_pending!(project :: Project.t(), pipeline :: Pipeline.t()) :: any()

  @callback notify_success!(project :: Project.t(), pipeline :: Pipeline.t()) :: any()

  @callback notify_failure!(project :: Project.t(), pipeline :: Pipeline.t()) :: any()

  @callback pull_request(
              project :: Project.t(),
              pr_number :: pos_integer(),
              installation_id :: pos_integer()
            ) :: map()

  @callback skip_ci?(commit_massage :: binary()) :: boolean()

  @callback sha_url(project :: Project.t(), pipeline :: Pipeline.t()) :: binary()
end
