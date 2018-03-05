defmodule AlloyCi.Web.Api.BuildsEventView do
  import AlloyCi.Web.ApiHelpers
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
      image: build.image,
      services: build.services,
      artifacts: [build.artifacts] || [],
      cache: [build.options["cache"]] || [],
      dependencies: build.dependencies
      # credentials: []
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
