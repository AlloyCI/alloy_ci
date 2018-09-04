defmodule Arc.Storage.Fake do
  @moduledoc false
  @spec put(any(), any(), {%{file_name: any()}, any()}) :: {:ok, any()}
  def put(_definition, _version, {file, _scope}) do
    {:ok, file.file_name}
  end

  @spec url(any(), any(), {map(), any()}, any()) :: binary()
  def url(_definition, _version, {file, _scope}, _options \\ []) do
    "/test/fixtures/#{file[:file_name]}" |> URI.encode()
  end

  @spec delete(any(), any(), any()) :: :ok
  def delete(_definition, _version, _file_and_scope) do
    :ok
  end
end
