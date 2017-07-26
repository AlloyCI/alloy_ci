defmodule AlloyCi.Web.BadgeController do
  use AlloyCi.Web, :controller
  alias AlloyCi.Projects

  def index(conn, %{"project_id" => id, "ref" => ref}, current_user, _claims) do
    with false <- Projects.private?(id) do
      badge = Projects.build_badge(id, ref)
      render(conn, "index.svg", badge: badge)
    else
      _ ->
        case Projects.can_access?(id, current_user) do
          true ->
            badge = Projects.build_badge(id, ref)
            render(conn, "index.svg", badge: badge)
          _ ->
            conn
            |> put_flash(:info, "Project not found")
            |> redirect(to: project_path(conn, :index))
        end
    end
  end
end
