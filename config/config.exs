use Mix.Config

# Example usage:
#
# config :exuvia,
#   accept: "ssh://*:*@localhost:2022",
#   host_keys_path: "/opt/your_elixir_project/priv/ssh"
#   max_sessions: 100,
#   shell_module: Exuvia.Shell

config :exuvia,
  accept: {:system, "EXUVIA_ACCEPT", "ssh://*:*@localhost:2022"}
