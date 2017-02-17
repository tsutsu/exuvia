# Exuvia

Exuvia abstracts away everything needed to connect to your Elixir node, via both SSH and the distribution protocol.

## Features

### Retrieve public keys and group memberships from Github

As if Github was your LDAP server! Just set these environment variables:

- `GITHUB_ACCESS_TOKEN`
- `GITHUB_AUTHORIZED_ORGS`

### Static backup password from env

If you fear for your ability to get into a server that relies on a third-party for AAA, you can also set this envrionment variable:

- `SSH_PASSWORD`

Any user will be able to log in using this password. (Not very safe for standard server setups, but quite safe+convenient if your env is handled through Docker Swarm or Kubernetes.)

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

