defmodule AlloyCi do
  @moduledoc """
  """
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AlloyCi.Supervisor]
    Supervisor.start_link(children(Mix.env), opts)
  end

  def children(env) when env != "test" do
    import Supervisor.Spec, warn: false
    children() ++ [worker(GuardianDb.ExpiredSweeper, [])]
  end

  def children do
    import Supervisor.Spec
    # Define workers and child supervisors to be supervised
    [
      # Start the Ecto repository
      supervisor(AlloyCi.Repo, []),
      # Start the endpoint when the application starts
      supervisor(AlloyCi.Endpoint, []),
      # Start your own worker by calling: AlloyCi.Worker.start_link(arg1, arg2, arg3)
      # worker(AlloyCi.Worker, [arg1, arg2, arg3]),
    ]
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    AlloyCi.Endpoint.config_change(changed, removed)
    :ok
  end
end
