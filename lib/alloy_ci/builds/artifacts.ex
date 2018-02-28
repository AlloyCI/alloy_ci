defmodule AlloyCi.Artifacts do
  @moduledoc """
  Intermediate module for Arc and the Build Artifacts
  """
  use Arc.Definition
  use Arc.Ecto.Definition

  def storage_dir(_, {_file, artifact}) do
    "uploads/artifacts/#{artifact.id}"
  end
end
