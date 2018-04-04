defmodule AlloyCi.ArtifactSweeper do
  @moduledoc """
  Periodically sweep expired artifacts from the main storage
  """
  use GenServer
  alias AlloyCi.Artifacts
  require Logger

  def start_link(interval, opts \\ []) do
    defaults = %{
      interval: parse_interval(interval)
    }

    state = Enum.into(opts, defaults)

    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @doc """
  Reset the sweep timer.
  """
  def reset_timer do
    GenServer.call(__MODULE__, :reset_timer)
  end

  @doc """
  Manually trigger an artifact sweep of expired artifacts. Also resets the current
  scheduled work.
  """
  def purge do
    GenServer.call(__MODULE__, :sweep)
  end

  def init(state) do
    {:ok, schedule_work(self(), state)}
  end

  def handle_call(:reset_timer, _from, state) do
    {:reply, :ok, schedule_work(self(), state)}
  end

  def handle_call(:sweep, _from, state) do
    {:reply, :ok, sweep(self(), state)}
  end

  def handle_info(:sweep, state) do
    {:noreply, sweep(self(), state)}
  end

  def handle_info(_, state), do: {:noreply, state}

  defp parse_interval(interval) do
    (interval || 24)
    |> hours_to_minutes()
    |> minute_to_ms()
  end

  defp hours_to_minutes(value) when is_binary(value) do
    value
    |> String.to_integer()
    |> hours_to_minutes()
  end

  defp hours_to_minutes(value) when value < 1, do: 60
  defp hours_to_minutes(value), do: round(value * 60)

  defp minute_to_ms(value) when is_binary(value) do
    value
    |> String.to_integer()
    |> minute_to_ms()
  end

  defp minute_to_ms(value) when value < 1, do: 1000
  defp minute_to_ms(value), do: round(value * 60 * 1000)

  defp schedule_work(pid, state) do
    if state[:timer] do
      Process.cancel_timer(state.timer)
    end

    timer = Process.send_after(pid, :sweep, state[:interval])
    Map.merge(state, %{timer: timer})
  end

  defp sweep(pid, state) do
    Logger.log(:info, "Deleting expired artifacts...")
    Artifacts.delete_expired()
    Logger.log(:info, "Done.")
    schedule_work(pid, state)
  end
end
