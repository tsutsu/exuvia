defmodule Exuvia.Daemon do
  @moduledoc ~S"""
  Exposes IEx over SSH.
  """

  require Logger

  use GenServer

  def start do
    Application.ensure_all_started(:ssh)
    GenServer.start(__MODULE__, nil, name: __MODULE__)
  end

  def start_link do
    Application.ensure_all_started(:ssh)
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def publickey_backend do
    {:ok, pkb} = GenServer.call(__MODULE__, :get_publickey_backend)
    pkb
  end

  @doc false
  def init(_) do
    accept =
      :exuvia
      |> Confex.get_env(:accept, "ssh://*:*@127.0.0.1:2022")

    bindspec = URI.parse(accept)
    max_sessions = Confex.get_env(:exuvia, :max_sessions, 25)
    shell_mod = Confex.get_env(:exuvia, :shell_module, Exuvia.Shell)

    ssh_opts =
      [
        system_dir: String.to_charlist(Exuvia.KeyBag.system_dir()),
        parallel_login: true,
        shell: fn username ->
          new_session_id = make_session_id(username)
          Process.put(:ssh_session_id, new_session_id)
          shell_mod.start(project: get_project_slug(), session_id: new_session_id)
        end,
        max_sessions: max_sessions,
        key_cb: Exuvia.KeyBag,
        connectfun: &on_success/3,
        disconnectfun: &on_disconnect/1,
        failfun: &on_failure/3,
        ssh_msg_debug_fun: fn
          _, false, msg, _ -> Logger.debug(msg)
          _, true, msg, _ -> Logger.info(msg)
        end
      ] ++ parse_userinfo(bindspec)

    {pkb, ssh_opts} =
      Keyword.pop(ssh_opts, :publickey_backend, {Exuvia.KeyBag.Dummy, [allow: :always]})

    server_state = %{publickey_backend: pkb}

    {:ok, pid} =
      :ssh.daemon(
        parse_host(bindspec.host),
        bindspec.port || 22,
        ssh_opts
      )

    Process.link(pid)

    Logger.info(fn ->
      [
        "listening on ssh://",
        bindspec.host,
        ":",
        inspect(bindspec.port),
        ", with a ",
        :blue,
        inspect(elem(pkb, 0)),
        :reset,
        " PKI backend"
      ]
      |> IO.ANSI.format()
    end)

    {:ok, server_state}
  end

  def handle_call(:get_publickey_backend, _from, %{publickey_backend: pkb} = state) do
    {:reply, {:ok, pkb}, state}
  end

  def handle_call(_msg, _from, state), do: {:noreply, state}

  defp parse_host("0.0.0.0"), do: :any
  defp parse_host("localhost"), do: :loopback
  defp parse_host("127.0.0.1"), do: :loopback
  defp parse_host("::1"), do: :loopback

  defp parse_host(hostname) when is_binary(hostname) do
    hostname = String.to_charlist(hostname)

    case :inet.parse_address(hostname) do
      {:ok, addr} ->
        addr

      {:error, :einval} ->
        {:ok, system_hostname} = :inet.gethostname()
        parse_host2(hostname, system_hostname)
    end
  end

  defp parse_host2(hostname, hostname), do: :loopback

  defp parse_host2(hostname, _) do
    {:ok, {:hostent, _, _, _, _, addrs}} = :inet_res.gethostbyname(hostname)
    List.first(addrs)
  end

  @password_auth_opts MapSet.new([:password, :user_passwords, :pwdfun])

  defp parse_userinfo(%URI{scheme: scheme, userinfo: userinfo}) do
    userinfo_parts =
      case userinfo do
        nil ->
          []

        "" ->
          []

        str when is_binary(str) ->
          str
          |> String.split(":")
          |> Enum.map(fn
            "" -> nil
            str -> str
          end)
      end

    auth_opts =
      case {scheme, userinfo_parts} do
        {"ssh", []} ->
          [
            publickey_backend: {Exuvia.KeyBag.POSIX, []}
          ]

        {"ssh", ["*", "*"]} ->
          [
            publickey_backend: {Exuvia.KeyBag.Dummy, [allow: :always]},
            pwdfun: fn _, _ -> true end
          ]

        {"ssh", ["$USER"]} ->
          [
            publickey_backend: {Exuvia.KeyBag.POSIX, [allowed_user: System.get_env("USER")]}
          ]

        {"ssh", [user]} ->
          [
            publickey_backend: {Exuvia.KeyBag.POSIX, [allowed_user: user]}
          ]

        {"ssh", ["*", password]} ->
          [password: String.to_charlist(password)]

        {"ssh", [user, password]} ->
          [user_passwords: [{String.to_charlist(user), String.to_charlist(password)}]]

        {"github+ssh", args} ->
          Exuvia.KeyBag.Github.auth_opts(args)
      end

    auth_opts_keys = auth_opts |> Keyword.keys() |> MapSet.new()

    auth_methods_enabled =
      case MapSet.disjoint?(auth_opts_keys, @password_auth_opts) do
        true -> 'publickey'
        false -> 'publickey,password'
      end

    [auth_methods: auth_methods_enabled] ++ auth_opts
  end

  defp on_disconnect(_reason) do
    username = Process.get(:remote_user)

    Logger.info(fn ->
      IO.ANSI.format([
        Exuvia.Shell.format_remote_user(username),
        " disconnected"
      ])
    end)
  end

  defp on_success(username, _address, method) do
    Process.put(:remote_user, username)

    Logger.info(fn ->
      [Exuvia.Shell.format_remote_user(username), " connected (", method, ")"]
    end)
  end

  defp on_failure(username, address, reason) do
    Logger.warn(fn ->
      ip = :inet.ntoa(address)

      [
        "Connection failed from ",
        IO.ANSI.format([:blue, username, "@", ip]),
        ": ",
        inspect(reason)
      ]
    end)
  end

  defp make_session_id(username) do
    {Exuvia.SessionCounter.take_next(), to_string(username)}
  end

  defp get_project_slug do
    if Code.ensure_loaded?(Mix) do
      project = Mix.Project.config()

      if Mix.Project.umbrella?() do
        nil
      else
        {to_string(project[:app]), project[:version] || "UNRELEASED"}
      end
    else
      app_module_str =
        :code.get_path()
        |> Enum.map(&to_string/1)
        |> Enum.filter(&String.ends_with?(&1, "/consolidated"))
        |> List.first()
        |> Path.dirname()
        |> Path.basename()
        |> String.split("-")
        |> List.first()

      if app_module_str do
        app_module = String.to_existing_atom(app_module_str)
        app_spec = Application.spec(app_module)
        {app_module_str, to_string(app_spec[:vsn])}
      else
        nil
      end
    end
  end
end
