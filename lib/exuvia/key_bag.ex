defmodule Exuvia.KeyBag do
  @moduledoc ~S"""
  Authenticates and authorizes public keys with pluggable strategies.
  """

  require Logger

  @behaviour :ssh_server_key_api

  require Logger

  def host_key(alg, opts) do
    :ssh_file.host_key(alg, opts)
  end

  def is_auth_key(key, user, _opts) do
    validate_key_for_user(:erlang.list_to_binary(user), key)
  end

  defp validate_key_for_user(user, key) do
    GenServer.call(__MODULE__, {:authenticate, user, key})
  end

  def system_dir do
    {:ok, host_key_dir} = GenServer.call(__MODULE__, :get_host_key_dir)
    host_key_dir
  end

  def reset do
    GenServer.call(__MODULE__, :reset)
  end


  @doc false
  def start do
    GenServer.start(__MODULE__, nil, name: __MODULE__)
  end

  @doc false
  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @doc false
  def init(_) do
    persistence_type = Application.get_env(:exuvia, :host_key, :ephemeral)
    host_key_dir = ensure_host_key_dir_exists(persistence_type)

    ensure_host_key_exists(host_key_dir, "rsa")
    ensure_host_key_exists(host_key_dir, "dsa")
    ensure_host_key_exists(host_key_dir, "ecdsa")

    {:ok, %{
      backend_module: nil,
      backend_state: nil,
      cache: Exuvia.AuthResponseCache.new,
      host_key_dir: host_key_dir
    }}
  end

  def terminate(_reason, _state), do: :ok

  def handle_call(:reset, _from, state) do
    {:reply, :ok, %{state | cache: Exuvia.AuthResponseCache.new}}
  end

  def handle_call({:authenticate, _, _} = msg, from, %{backend_module: nil} = state) do
    {backend_module, backend_init_args} = Exuvia.Daemon.publickey_backend()
    {:ok, backend_state} = backend_module.init(backend_init_args)
    handle_call(msg, from, %{state |
      backend_module: backend_module,
      backend_state: backend_state
    })
  end

  def handle_call({:authenticate, username, material}, _, %{cache: arc, backend_module: bmod, backend_state: bstate} = state) do
    {arc, cached_resp} = Exuvia.AuthResponseCache.by_request(arc, {username, material})
    if cached_resp do
      {:reply, cached_resp.granted, %{state | cache: arc}}
    else
      {granted, ttl, new_bstate} = bmod.auth_request(username, material, bstate)
      arc = Exuvia.AuthResponseCache.insert(arc, %Exuvia.AuthResponse{username: username, material: material, granted: granted, ttl: ttl})
      {:reply, granted, %{state | cache: arc, backend_state: new_bstate}}
    end
  end

  def handle_call(:get_host_key_dir, _, %{host_key_dir: hk_dir} = state) do
    {:reply, {:ok, hk_dir}, state}
  end

  defp ensure_host_key_dir_exists({:dir, dir_path}) do
    case File.stat!(dir_path).access do
      :none -> raise ArgumentError, "SSH host key directory '#{dir_path}' is inaccessible"
      _     -> dir_path
    end

  end

  defp ensure_host_key_dir_exists(:ephemeral) do
    dir_path = Path.join([:code.priv_dir(:exuvia), "host_keys"])
    File.mkdir_p!(dir_path)
    dir_path
  end

  def ensure_host_key_exists(dir, alg) do
    key_path = Path.join(dir, "ssh_host_#{alg}_key")

    unless File.exists?(key_path) do
      File.touch!(key_path)
      File.rm!(key_path)
      Logger.info "Creating SSH2 #{String.upcase(alg)} host key at '#{key_path}'"
      {_, 0} = System.cmd "ssh-keygen", ["-q", "-t", alg, "-N", "", "-f", key_path]
    end

    File.read!(key_path)
  end
end
