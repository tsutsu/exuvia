defmodule Exuvia.Mixfile do
  use Mix.Project

  def project do [
    app: :exuvia,
    version: "0.1.0",
    elixir: "~> 1.3",
    build_embedded: Mix.env == :prod,
    start_permanent: Mix.env == :prod,
    deps: deps()
  ] end

  def application do [
    mod: {Exuvia, []},
    applications: [:logger, :ssh, :tentacat]
  ] end

  defp deps do [
    {:temp, "~> 0.4.1"},
    {:tentacat, "~> 0.5.3"}
  ] end
end
