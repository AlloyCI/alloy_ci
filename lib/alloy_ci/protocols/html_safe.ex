defimpl Phoenix.HTML.Safe, for: Map do
  def to_iodata(data) do
    Poison.encode!(data)
  end
end
