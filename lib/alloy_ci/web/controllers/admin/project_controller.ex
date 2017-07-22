defmodule AlloyCi.Web.Admin.ProjectController do
  use AlloyCi.Web, :admin_controller

  alias AlloyCi.Projects

  # Make sure that we have a valid token in the :admin area of the session
  # We've aliased Guardian.Plug.EnsureAuthenticated in our AlloyCi.Web.admin_controller macro
  plug EnsureAuthenticated, handler: AlloyCi.Web.Admin.UserController, key: :admin

  def index(conn, params, current_user, _) do
    {projects, kerosene} = Projects.all(params)
    render conn, "index.html", current_user: current_user, kerosene: kerosene, projects: projects
  end

  def show(conn, %{"id" => id}, current_user, _) do
    project = Projects.get(id)
    render conn, "show.html", current_user: current_user, project: project
  end

  def delete(conn, %{"id" => id}, _, _) do
    {:ok, _} = Projects.delete_by(id: id)
    conn
    |> put_flash(:info, "Project was deleted successfully")
    |> redirect(to: admin_project_path(conn, :index))
  end
end
