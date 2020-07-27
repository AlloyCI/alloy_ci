defmodule AlloyCi.Web.ChannelCase do
  @moduledoc """
  This module defines the test case to be used by
  channel tests.

  Such tests rely on `Phoenix.ChannelTest` and also
  import other functionality to make it easier
  to build and query models.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with channels
      import Phoenix.ChannelTest

      alias AlloyCi.Repo
      import Ecto
      import Ecto.{Changeset, Query}

      # The default endpoint for testing
      @endpoint AlloyCi.Web.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(AlloyCi.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(AlloyCi.Repo, {:shared, self()})
    end

    :ok
  end
end
