# Exuvia

Exuvia abstracts away everything needed to connect to your Elixir node, via both SSH and the distribution protocol.

One interesting convenience feature Exuvia has is automatic public-key retrieval from Github. Just set these environment variables:

- `GITHUB_ACCESS_TOKEN`
- `GITHUB_AUTHORIZED_ORGS`

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `exuvia` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:exuvia, "~> 0.1.0"}]
    end
    ```

  2. Ensure `exuvia` is started before your application:

    ```elixir
    def application do
      [applications: [:exuvia]]
    end
    ```

