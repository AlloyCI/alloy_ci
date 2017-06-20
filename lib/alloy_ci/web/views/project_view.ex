defmodule AlloyCi.Web.ProjectView do
  use AlloyCi.Web, :view
  alias AlloyCi.{Accounts, Projects}
  import Kerosene.HTML

  def has_github_auth(user) do
    case Accounts.github_auth(user) do
      nil -> false
      _ -> true
    end
  end

  def integration_url do
    Application.get_env(:alloy_ci, :integration_url)
  end
end
