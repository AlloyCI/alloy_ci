defmodule AlloyCi.Web.Api.BuildsEventView do
  use AlloyCi.Web, :view
  @github_api Application.get_env(:alloy_ci, :github_api)

  def render("build.json", build) do
    %{
      id: build.id,
      token: build.token,
      allow_git_fetch: true,
      job_info: %{
        name: build.name,
        stage: build.stage,
        project_id: build.project_id,
        project_name: build.project.name
      },
      git_info: %{
        repo_url: @github_api.clone_url(build.project, build.pipeline),
        ref: build.pipeline.ref,
        before_sha: build.pipeline.before_sha,
        sha: build.pipeline.sha,
        ref_type: "branch"
      },
      runner_info: %{
        timeout: 3600
      },
      variables: build.variables,
      steps: build.steps,
      image: %{
        name: build.options["image"]
      },
      services: build.services,
      # artifacts: [], # Implement artifacts in version 1.0
      cache: [build.options["cache"]] || []
      # credentials: [],
      # dependencies: [] # Implement artifacts in version 1.0
    }
  end

  def render("error.json", %{changeset: changeset}) do
    errors = Enum.map(changeset.errors, fn {field, detail} ->
      %{
        source: field,
        title: "Invalid Attribute",
        detail: render_detail(detail)
      }
    end)

    %{errors: errors}
  end

  defp render_detail({message, values}) do
    Enum.reduce values, message, fn {k, v}, acc ->
      String.replace(acc, "%{#{k}}", to_string(v))
    end
  end

  defp render_detail(message) do
    message
  end
end
