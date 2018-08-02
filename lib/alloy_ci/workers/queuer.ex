defmodule AlloyCi.Queuer do
  @moduledoc """
  Wrapper around background jobs processing so that we don't
  need to check the env every time we need to enqueue a worker
  and so that we can change the way the jobs are processed
  if needed.
  """
  alias AlloyCi.BackgroundScheduler

  def push(worker, args) do
    unless Mix.env() == :test do
      BackgroundScheduler.push(worker, args)
    end
  end
end
