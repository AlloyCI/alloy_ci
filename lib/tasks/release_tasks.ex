defmodule AlloyCi.ReleaseTasks do
  @moduledoc """
  """
  @start_apps [
    :crypto,
    :ssl,
    :postgrex,
    :ecto
  ]

  @myapps [
    :alloy_ci
  ]

  @repos [
    AlloyCi.Repo
  ]

  def migrate do
    # Load application
    load_app()

    # Run migrations
    Enum.each(@myapps, &run_migrations_for/1)

    # Signal shutdown
    IO.puts "Success!"
    :init.stop()
  end

  def seed do
    load_app()

    # Run the seed script if it exists
    seed_script = seed_path(:alloy_ci)
    if File.exists?(seed_script) do
      IO.puts "Running seed script..."
      Code.eval_file(seed_script)
    end

    # Signal shutdown
    IO.puts "Success!"
    :init.stop()
  end

  def priv_dir(app), do: "#{:code.priv_dir(app)}"

  defp run_migrations_for(app) do
    IO.puts "Running migrations for #{app}"
    Ecto.Migrator.run(AlloyCi.Repo, migrations_path(app), :up, all: true)
  end

  defp load_app do
    IO.puts "Loading AlloyCI..."
    # Load the code for myapp, but don't start it
    :ok = Application.load(:alloy_ci)

    IO.puts "Starting dependencies..."
    # Start apps necessary for executing migrations
    Enum.each(@start_apps, &Application.ensure_all_started/1)

    # Start the Repo(s) for myapp
    IO.puts "Starting repos..."
    Enum.each(@repos, &(&1.start_link(pool_size: 1)))
  end

  defp migrations_path(app), do: Path.join([priv_dir(app), "repo", "migrations"])
  defp seed_path(app), do: Path.join([priv_dir(app), "repo", "seeds.exs"])
end
