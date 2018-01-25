defmodule Exuvia.Mixfile do
  use Mix.Project

  @version "0.2.2"

  def project, do: [
    app: :exuvia,
    version: @version,
    description: description(),
    package: package(),
    elixir: "~> 1.5",
    build_embedded: Mix.env == :prod,
    start_permanent: Mix.env == :prod,
    deps: deps()
  ]

  defp description, do: """
    Exuvia abstracts away everything needed to connect to your Elixir node, via both SSH and the distribution protocol.
  """

  defp package, do: [
    name: :exuvia,
    files: ["lib", "config", "mix.exs", "VERSION", "README.md", "LICENSE"],
    maintainers: ["Levi Aul"],
    licenses: ["BSD"],
    links: %{"GitHub" => "https://github.com/tsutsu/exuvia"}
  ]

  def application, do: [
    mod: {Exuvia, []},
    extra_applications: [:logger, :ssh]
  ]

  defp deps, do: [
    {:temp, "~> 0.4.3"},
    {:tentacat, "~> 0.7.2"},
    {:confex, "~> 3.3"},
    {:ex_doc, ">= 0.0.0", only: :dev},
    {:version_tasks, "~> 0.10.29", only: :dev}
  ]
end
