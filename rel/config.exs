# Import all plugins from `rel/plugins`
# They can then be used by adding `plugin MyPlugin` to
# either an environment, or release definition, where
# `MyPlugin` is the name of the plugin module.
["rel", "plugins", "*.exs"]
|> Path.join()
|> Path.wildcard()
|> Enum.map(&Code.eval_file(&1))

use Distillery.Releases.Config,
  # This sets the default release built by `mix release`
  default_release: :default,
  # This sets the default environment used by `mix release`
  default_environment: Mix.env()

# For a full list of config options for both releases
# and environments, visit https://hexdocs.pm/distillery/configuration.html

# You may define one or more environments in this file,
# an environment's settings will override those of a release
# when building in that environment, this combination of release
# and environment configuration is called a profile

environment :dev do
  set(dev_mode: true)
  set(include_erts: false)
  set(cookie: :">=8,0iuurgIHI^z~IPd.9HGF^hMn,V!ZA*3lwsgen}f`|P~yk>wW[Lvq2|UB*Z~5")
end

environment :prod do
  set(include_erts: false)
  set(include_src: false)
  set(cookie: :"_!G5WS]TDG^;|&vk4W?TDSQv}a&CFr^YP9@tG0(lbfYeN>mcaz)`h.H^uST{_=bY")
  set(post_start_hooks: "rel/hooks/post_start/")
end

# You may define one or more releases in this file.
# If you have not set a default release, or selected one
# when running `mix release`, the first release in the file
# will be used by default

release :alloy_ci do
  set(version: current_version(:alloy_ci))

  set(
    applications: [
      :runtime_tools
    ]
  )

  set(
    commands: [
      migrate: "rel/commands/migrate.sh"
    ]
  )
end
