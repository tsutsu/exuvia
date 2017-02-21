defmodule Exuvia.Mixfile do
  use Mix.Project

  @version File.read!("VERSION")

  def project do [
    app: :exuvia,
    version: @version,
    description: description(),
    package: package(),
    elixir: "~> 1.4",
    build_embedded: Mix.env == :prod,
    start_permanent: Mix.env == :prod,
    deps: deps()
  ] end

  defp description do
    """
    Exuvia abstracts away everything needed to connect to your Elixir node, via both SSH and the distribution protocol.
    """
  end

  defp package do [
    name: :exuvia,
    files: ["lib", "src", "config", "mix.exs", "VERSION", "README.md", "LICENSE"],
    maintainers: ["Levi Aul"],
    licenses: ["BSD"],
    links: %{"GitHub" => "https://github.com/meetwalter/exuvia"}
  ] end

  def application do [
    mod: {Exuvia, []},
    extra_applications: [:logger, :ssh]
  ] end

  defp deps do [
    {:temp, "~> 0.4.1"},
    {:tentacat, "~> 0.5.3"},
    {:ex_doc, ">= 0.0.0", only: :dev}
  ] end
end
