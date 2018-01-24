defmodule AlloyCi.Queuer do
  @moduledoc """
  Wrapper around Que.add so that we don't need to check the env
  every time we need to enqueue a worker
  """

  def push(worker, args) do
    unless Mix.env() == :test do
      Que.add(worker, args)
    end
  end
end
