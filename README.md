# Exuvia

Exuvia abstracts away everything needed to connect to your Elixir node, via both SSH and the distribution protocol.

Exuvia runs an Erlang-native SSH daemon and automatically handles authentication and authorization of users, in a way that is convenient for both development and production. No more headaches trying to `erl -remsh` through a firewall; just SSH in!

![An Exuvia connection to a node on the same machine](/../screenshots/local_connection.png?raw=true)

## Bind+accept Configuration

Exuvia's listener is configured (almost) entirely by setting a single app-env variable:

```elixir
  config :exuvia, :accept, "ssh://..."
```

The value of `:accept` is a URI string that represents both the `bind(3)` arguments for the SSH daemon listener (the host and port parts), and your choice of authentication/authorization strategy (in the schema, username, and password parts.) In most cases, it's the same URI you'd have to use, as a client, to connect!

If you don't set the value for `:accept`, the default value is `"ssh://*:*@localhost:2022"`. This will start a listener on only the loopback interface, on port 2022, and will authorize any user passing any password/key.

Exuvia uses [Confex](https://github.com/Nebo15/confex) for configuration, so you can also set `:accept` (or any of Exuvia's other options) using an OS environment variable, like so:

```elixir
  config :exuvia, {:system, "EXUVIA_ACCEPT"}
```

### `:accept`-string Cookbook

An OpenSSH-like public SSH server that depends on the filesystem (i.e. the host must have `/home/$user/.ssh/authorized_keys` files):

```elixir
  config :exuvia, :accept, "ssh://0.0.0.0:2022"
```

An SSH server with a single, global password, and no public-key authentication:

```elixir
  config :exuvia, :accept, "ssh://*:hunter2@localhost:2022"
```

An OpenSSH-behaving server, that only allows one particular user to authenticate, and relies on PKI (no password option):

```elixir
  config :exuvia, :accept, "ssh://bob@localhost:2022"
```

An OpenSSH-behaving server, that only allows *the user the Erlang-node runs as* to authenticate, and only via PKI:

```elixir
  config :exuvia, :accept, "ssh://$USER@localhost:2022"
```

A server that binds to a new ephemeral port on each node boot (important if you're running multiple instances of your node at once):

```elixir
  config :exuvia, :accept, "ssh://localhost:0"
```

### GitHub authentication!

Rather than managing keys on your Erlang node host—or managing an LDAP/Kerberos server or whatever else—Exuvia allows you to use GitHub as an LDAP-like server. (GitHub does have a public API for retrieving people's public SSH keys, after all.)

This is the best thing since sliced bread if you're a small devops team (like most Elixir shops are.) A representation of your team and its credentials likely already exists on GitHub. Why duplicate it elsewhere?

Here's the magic:

```elixir
  config :exuvia, :accept, "github+ssh://org1,org2:mytoken@0.0.0.0:2022"
```

This line configures Exuvia to connect to GitHub using a GitHub access token—`mytoken` above—and ask it two questions about each connecting user:

1. what are their registered public keys (and does the client's SSH challenge-response match any of them)?

2. what *GitHub organizations* does the client's passed username belong to, and do any of them match any of the orgs (`org1` and `org2` above) whose members are allowed in?

This is surprisingly secure: just tell Exuvia a GitHub organization name, and suddenly exactly the set of people in that organization will be able to connect to your node, using exactly the keys they have registered with GitHub. This is pleasantly stateless: it works just as well on your development machine as it does on a production server. You can just leave it running everywhere your code is. Say goodbye to local dummy auth strategies.👋

And don't worry: the responses from GitHub are cached, so frequent visits by SSH-probing bots won't get your GitHub account disabled.

## Installation

  1. Add `exuvia` to your list of dependencies in `mix.exs`:

  ```elixir
  def deps, do: [
    {:exuvia, "~> 0.2.0"}
  ]
  ```

  2. Add a `config :exuvia, accept: "..."` line to your `config.exs`.

#### Additional setup for using the GitHub authentication strategy

1. [Create a GitHub personal access token](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/). The token's owner should be a user with the right to view the organization's member list.

2. Ensure, for each GitHub user that should be able to connect, that [their visibility within your GitHub organization is set to public](https://help.github.com/articles/publicizing-or-hiding-organization-membership/). Users with private visibility don't appear in the organization's members list.

3. Ensure your users [have their up-to-date SSH keys registered with GitHub](https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/).

## Other Configuration

* `:host_keys_path` (optional): a directory containing pre-existing SSH host keys for the SSH daemon to use. E.g.

  ```elixir
    config :exuvia, host_keys_path: "/opt/your_elixir_project/priv/ssh"
  ```

  If this value is not set, a directory will be created under `deps/exuvia/priv` and new keys will be auto-generated there.

  **NOTE**: If you're using Elixir in Docker, I would heavily suggest creating a persistent `ssh-host-keys` volume and configuring Exuvia to use it. Otherwise, your SSH clients will likely spit out `known-hosts`-file mismatch errors.

* `:max_sessions` (optional): the number of simultaneous SSH connections. Defaults to 25.

* `:shell_module` (optional): a module possessing a function `start/1`, which will get called to create a shell upon successful connections. Look at [lib/exuvia/shell.ex](https://github.com/tsutsu/exuvia/blob/master/lib/exuvia/shell.ex) for an example.
