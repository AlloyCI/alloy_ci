defmodule AlloyCi.Web.RunnerController do
  use AlloyCi.Web, :controller

  alias AlloyCi.{Runner, Runners}

  plug(EnsureAuthenticated, handler: AlloyCi.Web.AuthController, typ: "access")

  def show(conn, %{"id" => id}, current_user, _) do
    runner = Runners.get(id)
    changeset = Runner.changeset(runner)
    render(conn, "show.html", current_user: current_user, changeset: changeset, runner: runner)
  end

  def update(conn, %{"id" => id, "runner" => runner_params}, current_user, _) do
    with {:ok, runner} <- Runners.can_manage?(id, current_user),
         {:ok, runner} <- Runners.update(runner, runner_params) do
      conn
      |> put_flash(:info, "Runner updated successfully.")
      |> redirect(to: runner_path(conn, :show, runner))
    else
      {:error, _} ->
        conn
        |> put_flash(:error, "Failed to update runner.")
        |> redirect(to: runner_path(conn, :show, id))
    end
  end

  def delete(conn, %{"id" => id}, current_user, _) do
    with {:ok, runner} <- Runners.can_manage?(id, current_user),
         {:ok, _} <- Runners.delete_by(id: id) do
      conn
      |> put_flash(:info, "Runner deleted successfully.")
      |> redirect(to: project_path(conn, :show, runner.project_id))
    else
      _ ->
        conn
        |> put_flash(:info, "Could not delete runner.")
        |> redirect(to: project_path(conn, :index))
    end
  end
end
