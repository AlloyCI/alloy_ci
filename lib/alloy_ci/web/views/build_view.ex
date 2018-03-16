defmodule AlloyCi.Web.BuildView do
  use AlloyCi.Web, :view
  import AlloyCi.Web.ProjectView, only: [clean_ref: 1, ref_icon: 1, tags: 1]
  import AlloyCi.Web.PipelineView, only: [build_duration: 1]

  def artifact_for(conn, %{artifacts: %{}, artifact: artifact} = build)
      when not is_nil(artifact) do
    [
      content_tag :div, class: "h4" do
        [
          icon("file-archive-o", "fa-lg"),
          " ",
          link_to(conn, artifact, build)
        ]
      end,
      content_tag :p do
        "Expiry: #{from_now(artifact.expires_at)}"
      end,
      keep_button_link(conn, build)
    ]
  end

  def artifact_for(_, _) do
    content_tag :p do
      "No artifacts were generated for this build."
    end
  end

  def from_now(nil), do: "Never"

  def from_now(time) do
    time |> Timex.from_now()
  end

  def runner(nil), do: "Pending"
  def runner(id), do: "##{id}"

  defp keep_button_link(_, %{artifact: %{expires_at: nil}}), do: ""

  defp keep_button_link(conn, %{artifact: artifact} = build) do
    if Timex.after?(artifact.expires_at, Timex.now()) do
      content_tag :span do
        link(
          "Keep artifacts forever",
          to: project_build_keep_artifact_path(conn, :keep_artifact, build.project_id, build),
          class: "btn btn-secondary m-t-1"
        )
      end
    else
      ""
    end
  end

  defp link_to(conn, %{expires_at: ex} = artifact, build) when not is_nil(ex) do
    if Timex.after?(ex, Timex.now()) do
      link(
        artifact.file[:file_name],
        to: project_build_artifact_path(conn, :artifact, build.project, build)
      )
    else
      artifact.file[:file_name]
    end
  end

  defp link_to(conn, artifact, build) do
    link(
      artifact.file[:file_name],
      to: project_build_artifact_path(conn, :artifact, build.project, build)
    )
  end
end
