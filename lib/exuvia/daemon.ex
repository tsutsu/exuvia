defmodule Exuvia.Daemon do
  @moduledoc ~S"""
  Exposes IEx over SSH.
  """

  require Logger
  alias Logger, as: L

  use GenServer

  @doc false
  def start do
    Application.ensure_all_started(:ssh)
    GenServer.start(__MODULE__, nil, name: __MODULE__)
  end

  @doc false
  def start_link do
    Application.ensure_all_started(:ssh)
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @doc false
  def init(_) do
    max_sessions = Application.get_env(:exuvia, :max_sessions, 25)

    ssh_opts = [
      system_dir: String.to_charlist(Exuvia.KeyBag.system_dir),
      parallel_login: true,
      max_sessions: max_sessions,
      key_cb: Exuvia.KeyBag,
      connectfun: &on_success/3,
      failfun: &on_failure/3
    ]

    auth_opts = case System.get_env("SSH_PASSWORD") do
      pw when is_binary(pw) ->
        [auth_methods: 'publickey,password', password: String.to_charlist(pw)]
      nil ->
        [auth_methods: 'publickey']
    end

    {:ok, pid} = :ssh.daemon(2022, ssh_opts ++ auth_opts)

    Process.link(pid)

    {:ok, []}
  end


  defp on_success(username, _address, method) do
    L.info fn ->
      ["Authenticated ", IO.ANSI.format([:blue, username]), " (", method, ")"]
    end
  end

  defp on_failure(username, address, reason) do
    L.warn fn ->
      ip = :inet.ntoa(address)
      ["Connection failed from ", IO.ANSI.format([:blue, username, "@", ip]), ": ", inspect(reason)]
    end
  end
end
