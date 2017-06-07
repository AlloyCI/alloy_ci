defmodule AlloyCi.ExqEnqueuer do
  @moduledoc """
  Wraper around Exq.enqueue so that we don't need to check the env
  everytime we need to enqueue a worker
  """

  def push(worker, args, options \\ [], queue \\ "default") do
    unless Mix.env == :test do
      Exq.enqueue(Exq, queue, worker, args, options)
    end
  end
end
