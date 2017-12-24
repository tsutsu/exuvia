# Exuvia

Exuvia abstracts away everything needed to connect to your Elixir node, via both SSH and the distribution protocol.

Exuvia runs an Erlang-native SSH daemon and automatically handles authentication and authorization of users, in a way that is convenient for both development and production. No more headaches trying to `erl -remsh` through a firewall; just SSH in!

![An Exuvia connection to a node on the same machine](/../screenshots/local_connection.png?raw=true)

## Minimal configuration

Exuvia is configured entirely by setting a single environment variable, `$EXUVIA_ACCEPT`; or by setting the single app-env variable:

```
  config :exuvia, :accept, "..."
```

The value of both of these is a pseudo-URI, that represents both the `bind(3)` arguments for the SSH daemon listener, and the authentication/authorization configuration. In most cases, it's the same URI you'd have to use, as a client, to connect!

If you don't set the value at all, the default value is `"ssh://*:*@localhost:2022"`. This will start a listener on only the loopback interface, on port 2022, and will authorize any user passing any password/key.

## `$EXUVIA_ACCEPT` Examples

An OpenSSH-like public SSH server that depends on the filesystem (i.e. the host must have `/home/$user/.ssh/authorized_keys` files):

```
export EXUVIA_ACCEPT='ssh://0.0.0.0:2022'
```

An SSH server with a single, global password, and no public-key authentication:

```
export EXUVIA_ACCEPT='ssh://*:hunter2@localhost:2022'
```

An OpenSSH-behaving server, that only allows one particular user to authenticate, and relies on PKI (no password option):

```
export EXUVIA_ACCEPT='ssh://bob@localhost:2022'
```

An OpenSSH-behaving server, that only allows *the user the Erlang-node runs as* to authenticate, and only via PKI:

```
export EXUVIA_ACCEPT='ssh://$USER@localhost:2022'
```

A server that binds to a new ephemeral port on each node boot (important if you're running multiple instances of your node at once):

```
export EXUVIA_ACCEPT='ssh://localhost:0'
```

## GitHub authentication!

Rather than managing keys on your Erlang node host—or managing an LDAP/Kerberos server or whatever else—Exuvia allows you to use GitHub as an LDAP-like server. (GitHub does have a public API for retrieving people's public SSH keys, after all.)

This is the best thing since sliced bread if you're a small devops team (like most Elixir shops are.) A representation of your team and its credentials likely already exists on GitHub. Why duplicate it elsewhere?

Here's the magic:

```
export EXUVIA_ACCEPT='github+ssh://org1,org2:mytoken@0.0.0.0:2022'
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

  2. Set the `$EXUVIA_ACCEPT` environment variable, or add the app-env var to your `config.exs`.

(My own preferred setup is to put the environment variable in a [direnv](https://direnv.net) `.envrc` file during development, and then, in production, to make the environment variable a Kubernetes secret attached to the deployment.)

#### Ecosystem preparation for the GitHub authentication strategy

1. [Create a GitHub personal access token](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/). The token's owner should be a user with the right to view the organization's member list.

2. Ensure, for each GitHub user that should be able to connect, that [their visibility within your GitHub organization is set to public](https://help.github.com/articles/publicizing-or-hiding-organization-membership/). Users with private visibility don't appear in the organization's members list.

3. Ensure your users [have their up-to-date SSH keys registered with GitHub](https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/).
