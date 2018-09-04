defmodule AlloyCi.Version do
  @moduledoc """
  Helper Module to keep track of the application version.
  To update the version, changes to this file and mix.exs are required.
  """

  @version "0.8.0"

  @spec version() :: binary()
  def version do
    @version
  end
end
