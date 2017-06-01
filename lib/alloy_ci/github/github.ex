defmodule AlloyCi.Github do
  @moduledoc """
  Defines the behaviour for interacting with the GitHub API. There is a production
  implementation, and a test implementation of this behaviour.
  """
  alias AlloyCi.{Pipeline, Project, User}

  @callback alloy_ci_config(project :: %Project{}, pipeline :: %Pipeline{}) :: String.t

  @callback api_client(token :: String.t) :: any

  @callback clone_url(project :: %Project{}, pipeline :: %Pipeline{}) :: String.t

  @callback fetch_repos(token :: String.t) :: Map.t

  @callback notify_pending!(project :: %Project{}, pipeline :: %Pipeline{}) :: any

  @callback notify_success!(project :: %Project{}, pipeline :: %Pipeline{}) :: any

  @callback notify_failure!(project :: %Project{}, pipeline :: %Pipeline{}) :: any

  @callback repos_for(user :: %User{}) :: Map.t
end
