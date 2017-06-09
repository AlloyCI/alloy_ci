defmodule AlloyCi.Web.ProjectView do
  use AlloyCi.Web, :view
  alias AlloyCi.Accounts
  import Kerosene.HTML

  def has_github_auth(user) do
    case Accounts.github_auth(user) do
      nil -> false
      _ -> true
    end
  end
end
