defmodule AlloyCi.BuildsTraceCache do
  @moduledoc """
  ETS cache to store the incoming build trace while builds are running.
  After a build has finished, the runner re-sends the entire trace as a
  single update, so that's when it should be saved to the DB.
  """
  use GenServer
  require Logger

  @table __MODULE__

  # Client API

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(state \\ %{}) do
    Logger.info("Starting builds trace cache")
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @spec delete(pos_integer()) :: boolean()
  def delete(build_id) do
    GenServer.call(__MODULE__, {:delete, build_id})
  end

  @spec lookup(pos_integer()) :: binary()
  def lookup(build_id) do
    GenServer.call(__MODULE__, {:lookup, build_id})
  end

  @spec insert(pos_integer(), binary()) :: :ok
  def insert(build_id, trace) do
    GenServer.cast(__MODULE__, {:insert, {build_id, trace}})
  end

  # Server API

  @impl true
  @spec init(any()) :: {:ok, any()}
  def init(state) do
    :ets.new(@table, [:named_table, read_concurrency: true, write_concurrency: true])

    {:ok, state}
  end

  @impl true
  def handle_call({:delete, build_id}, _from, state) do
    result = :ets.delete(@table, build_id)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:lookup, build_id}, _from, state) do
    with [{_, trace}] <- :ets.lookup(@table, build_id) do
      {:reply, trace, state}
    else
      _ ->
        {:reply, "", state}
    end
  end

  @impl true
  def handle_cast({:insert, {build_id, trace}}, state) do
    :ets.insert(@table, {build_id, trace})
    {:noreply, state}
  end
end
