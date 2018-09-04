defimpl Phoenix.HTML.Safe, for: Map do
  @spec to_iodata(any()) ::
          binary()
          | maybe_improper_list(
              binary() | maybe_improper_list(any(), binary() | []) | byte(),
              binary() | []
            )
  def to_iodata(data) do
    Poison.encode!(data, pretty: true)
  end
end
