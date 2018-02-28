defmodule Arc.Storage.Fake do
  @moduledoc false
  def put(_definition, _version, {file, _scope}) do
    {:ok, file.file_name}
  end

  def url(_definition, _version, {file, _scope}, _options \\ []) do
    "/test/fixtures/#{file[:file_name]}" |> URI.encode()
  end

  def delete(_definition, _version, _file_and_scope) do
    :ok
  end
end
