ExUnit.start

Ecto.Adapters.SQL.Sandbox.mode(AlloyCi.Repo, :manual)
ExVCR.Config.cassette_library_dir("test/fixtures/vcr_cassettes")
