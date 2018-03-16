defmodule AlloyCi.Application do
  @moduledoc """
  """
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AlloyCi.Supervisor]
    Supervisor.start_link(children(Mix.env()), opts)
  end

  def children(env) when env != "test" do
    import Supervisor.Spec, warn: false
    children()
  end

  def children do
    import Supervisor.Spec
    # Define workers and child supervisors to be supervised
    [
      # Start the Ecto repository
      supervisor(AlloyCi.Repo, []),
      # Start the endpoint when the application starts
      supervisor(AlloyCi.Web.Endpoint, []),
      worker(Guardian.DB.Token.SweeperServer, []),
      worker(AlloyCi.ArtifactSweeper, [])
      # Start your own worker by calling: AlloyCi.Worker.start_link(arg1, arg2, arg3)
      # worker(AlloyCi.Worker, [arg1, arg2, arg3]),
    ]
  end
end
