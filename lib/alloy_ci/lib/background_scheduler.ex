defmodule AlloyCi.BackgroundScheduler do
  @moduledoc """
  GenServer used to kick off background processes.
  Functionality is basic for now, extra functionality might come in the future.
  """
  use GenServer
  require Logger

  # Client API

  def start_link(state \\ %{}) do
    Logger.info("Starting background scheduler")
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def push(worker, args) do
    GenServer.cast(__MODULE__, {:push, {worker, args}})
  end

  # Server API

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:push, {worker, args}}, state) do
    Task.start(fn ->
      Logger.info("Starting #{worker}")
      worker.perform(args)
      Logger.info("Finishing #{worker}")
    end)

    {:noreply, state}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}
end
