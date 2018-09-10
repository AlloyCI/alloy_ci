defmodule AlloyCi.Web.ProjectController do
  use AlloyCi.Web, :controller
  alias AlloyCi.{Project, Projects, Queuer, Workers}
  import Phoenix.HTML.Link
  import AlloyCi.Web.ProjectView, only: [app_url: 0]

  plug(EnsureAuthenticated, handler: AlloyCi.Web.AuthController, typ: "access")

  def index(conn, params, current_user, _claims) do
    {projects, kerosene} = Projects.paginated_for(current_user, params)
    render(conn, "index.html", kerosene: kerosene, projects: projects, current_user: current_user)
  end

  def new(conn, _params, current_user, _claims) do
    Queuer.push(Workers.FetchReposWorker, {current_user.id, get_csrf_token()})

    render(conn, "new.html", current_user: current_user)
  end

  def create(conn, %{"project" => project_params}, current_user, _claims) do
    case Projects.create_project(project_params, current_user) do
      {:ok, project} ->
        conn
        |> put_flash(:info, "Project created successfully.")
        |> redirect(to: project_path(conn, :show, project))

      {:missing_installation, _} ->
        conn
        |> put_flash(:error, [
          "This project's organization is not configured to use AlloyCI. Please go to the ",
          link("GitHub Integration", to: app_url(), target: "_blank", class: "flash-link"),
          " page to configure AlloyCI for this organization."
        ])
        |> redirect(to: project_path(conn, :index))

      {:missing_config, _} ->
        conn
        |> put_flash(:error, [
          "The selected project doesn't have an .alloy-ci.yml config file. Please see the ",
          link(
            "documentation",
            to: "https://github.com/AlloyCI/alloy_ci/tree/master/doc",
            target: "_blank",
            class: "flash-link"
          ),
          " for information on how to add one."
        ])
        |> redirect(to: project_path(conn, :index))

      {:error, _} ->
        conn
        |> put_flash(:error, "There was an error creating your project. Please try again.")
        |> redirect(to: project_path(conn, :index))
    end
  end

  def show(conn, %{"id" => id} = params, current_user, _claims) do
    case Projects.show_by(id, current_user, %{"page" => params["page"]}) do
      {:ok, {project, pipelines, kerosene}} ->
        render(
          conn,
          "show.html",
          project: project,
          pipelines: pipelines,
          kerosene: kerosene,
          current_user: current_user
        )

      {:error, nil} ->
        conn
        |> put_flash(:info, "Project not found")
        |> redirect(to: project_path(conn, :index))
    end
  end

  def edit(conn, %{"id" => id}, current_user, _claims) do
    with {:ok, project} <- Projects.get_by(id, current_user, preload: :runners) do
      changeset = Project.changeset(project)

      render(
        conn,
        "edit.html",
        project: project,
        changeset: changeset,
        current_user: current_user
      )
    else
      {:error, nil} ->
        conn
        |> put_flash(:info, "Project not found")
        |> redirect(to: project_path(conn, :index))
    end
  end

  def update(conn, %{"id" => id, "project" => project_params}, current_user, _claims) do
    with {:ok, project} <- Projects.get_by(id, current_user, preload: :runners) do
      case Projects.update(project, project_params) do
        {:ok, project} ->
          conn
          |> put_flash(:info, "Project updated successfully.")
          |> redirect(to: project_path(conn, :edit, project))

        {:error, changeset} ->
          render(
            conn,
            "edit.html",
            project: project,
            changeset: changeset,
            current_user: current_user
          )
      end
    else
      {:error, nil} ->
        conn
        |> put_flash(:info, "Project not found")
        |> redirect(to: project_path(conn, :index))
    end
  end

  def delete(conn, %{"id" => id}, current_user, _claims) do
    with {:ok, _} <- Projects.delete_by(id, current_user) do
      conn
      |> put_flash(:info, "Project deleted successfully.")
      |> redirect(to: project_path(conn, :index))
    else
      {:error, nil} ->
        conn
        |> put_flash(:info, "Project not found")
        |> redirect(to: project_path(conn, :index))
    end
  end
end
