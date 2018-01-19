defmodule AlloyCi.Web.Admin.ProjectController do
  use AlloyCi.Web, :admin_controller

  alias AlloyCi.{Project, Projects}

  plug(EnsureAuthenticated, handler: AlloyCi.Web.Admin.UserController, key: :admin)

  def index(conn, params, current_user, _) do
    {projects, kerosene} = Projects.all(params)
    render(conn, "index.html", current_user: current_user, kerosene: kerosene, projects: projects)
  end

  def show(conn, %{"id" => id}, current_user, _) do
    project = Projects.get(id)
    changeset = Project.changeset(project)
    render(conn, "show.html", current_user: current_user, project: project, changeset: changeset)
  end

  def update(conn, %{"id" => id, "project" => project_params}, current_user, _claims) do
    project = Projects.get(id)

    case Projects.update(project, project_params) do
      {:ok, project} ->
        conn
        |> put_flash(:info, "Project updated successfully.")
        |> redirect(to: admin_project_path(conn, :show, project))

      {:error, changeset} ->
        render(
          conn,
          "show.html",
          project: project,
          changeset: changeset,
          current_user: current_user
        )
    end
  end

  def delete(conn, %{"id" => id}, _, _) do
    {:ok, _} = Projects.delete_by(id: id)

    conn
    |> put_flash(:info, "Project was deleted successfully")
    |> redirect(to: admin_project_path(conn, :index))
  end
end
