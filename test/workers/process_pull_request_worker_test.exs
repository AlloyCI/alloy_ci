defmodule AlloyCi.ProcessPullRequestWorkerTest do
  @moduledoc """
  """
  use AlloyCi.DataCase
  alias AlloyCi.{Pipeline, Workers.ProcessPullRequestWorker}
  import AlloyCi.Factory

  setup do
    {:ok, %{project: insert(:project, repo_id: 35129377)}}
  end

  test "it creates the pipeline if PR is from fork", %{project: project} do
    params = Poison.decode!(File.read!("test/fixtures/requests/pull_request_created.json"))
    ProcessPullRequestWorker.perform(params)

    pipeline =
      Pipeline
      |> where(project_id: ^project.id)
      |> Repo.one

    assert pipeline.ref == "baxterthehacker:changes"
    assert pipeline.before_sha == "9049f1265b7d61be4a8904a9a27120d2064dab3b"
    assert pipeline.sha == "0d1a26e67d8f5eaf1f6ba5c57fc3c7d91ac0fd1c"
    assert pipeline.installation_id == params["installation"]["id"] 
    assert pipeline.commit["pr_commit_message"] =~ "test commit"
    assert pipeline.commit["message"] =~ "README"
  end

  test "it creates nothing if PR not from fork", %{project: project} do
    params = %{"pull_request" => %{"head" => %{"repo" => %{"fork" => false}}}}
    ProcessPullRequestWorker.perform(params)
    
    pipeline =
      Pipeline
      |> where(project_id: ^project.id)
      |> Repo.one

    assert pipeline == nil  
  end
end
