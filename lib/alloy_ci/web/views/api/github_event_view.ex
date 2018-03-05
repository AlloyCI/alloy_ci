defmodule AlloyCi.Web.Api.GithubEventView do
  import AlloyCi.Web.ApiHelpers

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
end
