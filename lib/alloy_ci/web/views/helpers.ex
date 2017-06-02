defmodule AlloyCi.Web.ViewHelpers do
  @moduledoc """
  """
  @github_api Application.get_env(:alloy_ci, :github_api)

  def active_on_current(%{request_path: path}, path), do: "active"
  def active_on_current(_, _), do: ""

  def admin_logged_in?(conn), do: Guardian.Plug.authenticated?(conn, :admin)
  def admin_user(conn), do: Guardian.Plug.current_resource(conn, :admin)

  def callout("success"), do: "callout-success"
  def callout("failed"), do: "callout-danger"
  def callout("running"), do: "callout-warning"
  def callout(_), do: ""

  def current_user(conn), do: Guardian.Plug.current_resource(conn)

  def icon(name) do
    {:safe, "<i class='fa fa-#{name}'></i>"}
  end

  def icon("identity", classes), do: icon("vcard", classes)

  def icon(name, classes) do
    {:safe, "<i class='fa fa-#{name} #{classes}'></i>"}
  end

  def logged_in?(conn), do: Guardian.Plug.authenticated?(conn)

  def pretty_commit(msg) do
    msg |> String.split("\n") |> List.first
  end

  def sha_link(pipeline) do
    {:safe, "<a href='#{@github_api.sha_url(pipeline.project, pipeline)}'>#{pipeline.sha |> String.slice(0..7)}</a>"}
  end

  def sha_link(pipeline, project) do
    {:safe, "<a href='#{@github_api.sha_url(project, pipeline)}'>#{pipeline.sha |> String.slice(0..7)}</a>"}
  end

  def status_btn("success"), do: "btn-success"
  def status_btn("failed"), do: "btn-danger"
  def status_btn("running"), do: "btn-warning"
  def status_btn(_), do: "btn-outline-secondary active"

  def status_icon("created"), do: icon("calendar")
  def status_icon("failed"),  do: icon("close")
  def status_icon("pending"), do: icon("circle-o-notch")
  def status_icon("running"), do: icon("circle-o-notch", "fa-spin")
  def status_icon("success"), do: icon("check")
end
