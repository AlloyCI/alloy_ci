defmodule AlloyCi.Web.Api.GithubEventView do
  use AlloyCi.Web, :view

  def render("event.json", %{event: event}) do
    %{
      status: event.status,
      message: event.message
    }
  end

  def render("error.json", %{changeset: changeset}) do
    errors =
      Enum.map(changeset.errors, fn {field, detail} ->
        %{
          source: field,
          title: "Invalid Attribute",
          detail: render_detail(detail)
        }
      end)

    %{errors: errors}
  end

  defp render_detail({message, values}) do
    Enum.reduce(values, message, fn {k, v}, acc ->
      String.replace(acc, "%{#{k}}", to_string(v))
    end)
  end

  defp render_detail(message) do
    message
  end
end
