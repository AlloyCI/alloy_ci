defmodule AlloyCi.BackgroundScheduler do
  @moduledoc """
  GenServer used to kick off background processes.
  Functionality is basic for now, extra functionality, like storing which jobs
  have been processed, or retry functionality might come in the future.
  """
  use GenServer
  require Logger
  alias AlloyCi.TaskSupervisor

  # Client API

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(state \\ %{}) do
    Logger.info("Starting background scheduler")
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @spec push(any(), any()) :: :ok
  def push(worker, args) do
    GenServer.cast(__MODULE__, {:push, {worker, args}})
  end

  # Server API

  @impl true
  @spec init(any()) :: {:ok, any()}
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:push, {worker, args}}, state) do
    Task.Supervisor.start_child(
      TaskSupervisor,
      fn ->
        Logger.info("Starting #{worker}")
        worker.perform(args)
        Logger.info("Finishing #{worker}")
      end,
      restart: :transient
    )

    {:noreply, state}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}
end
