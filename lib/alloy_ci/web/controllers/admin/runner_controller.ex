defmodule AlloyCi.Web.Admin.RunnerController do
  use AlloyCi.Web, :admin_controller

  alias AlloyCi.{Runner, Runners}

  # Make sure that we have a valid token in the :admin area of the session
  # We've aliased Guardian.Plug.EnsureAuthenticated in our AlloyCi.Web.admin_controller macro
  plug EnsureAuthenticated, handler: AlloyCi.Web.Admin.UserController, key: :admin

  def index(conn, params, current_user, _claims) do
    {runners, kerosene} = Runners.all(params)
    render conn, "index.html", current_user: current_user, kerosene: kerosene, runners: runners
  end

  def show(conn, %{"id" => id}, current_user, _) do
    runner = Runners.get(id)
    changeset = Runner.changeset(runner)
    render conn, "show.html", current_user: current_user, changeset: changeset, runner: runner
  end

  def update(conn, %{"id" => id, "runner" => runner_params}, current_user, _) do
    runner = Runners.get(id)
    case Runners.update(runner, runner_params) do
      {:ok, runner} ->
        conn
        |> put_flash(:info, "Runner updated successfully.")
        |> redirect(to: admin_runner_path(conn, :show, runner))
      {:error, changeset} ->
        render(conn, "show.html", runner: runner, changeset: changeset, current_user: current_user)
    end
  end

  def delete(conn, %{"id" => id}, _, _) do
    {:ok, _} = Runners.delete_by(id: id)

    conn
    |> put_flash(:info, "Runner was deleted successfully")
    |> redirect(to: admin_runner_path(conn, :index))
  end
end
