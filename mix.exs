defmodule Exuvia.Mixfile do
  use Mix.Project

  @version File.read!("VERSION")

  def project do [
    app: :exuvia,
    version: @version,
    elixir: "~> 1.4",
    build_embedded: Mix.env == :prod,
    start_permanent: Mix.env == :prod,
    deps: deps()
  ] end

  def application do [
    mod: {Exuvia, []},
    extra_applications: [:logger, :ssh]
  ] end

  defp deps do [
    {:temp, "~> 0.4.1"},
    {:tentacat, "~> 0.5.3"}
  ] end
end
