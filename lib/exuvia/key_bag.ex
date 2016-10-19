require Logger

defmodule Exuvia.KeyBag do
  @moduledoc ~S"""
  Authenticates and authorizes public keys with pluggable strategies.
  """

  @behaviour :ssh_server_key_api

  def host_key(:"ssh-rsa", _), do: get_host_key("rsa")
  def host_key(:"ssh-dss", _), do: get_host_key("dsa")
  def host_key(:"ecdsa-sha2-nistp256", _), do: get_host_key("ecdsa")
  def host_key(:"ecdsa-sha2-nistp384", _), do: get_host_key("ecdsa")
  def host_key(:"ecdsa-sha2-nistp521", _), do: get_host_key("ecdsa")
  def host_key(_, _), do: {:error, 'Not implemented!'}

  def is_auth_key(key, user, _opts) do
    validate_key_for_user(:erlang.list_to_binary(user), key)
  end


  defp get_host_key(alg) do
    persistence_type = Application.get_env(:exuvia, :host_key, :ephemeral)
    pem = get_privkey_pem(persistence_type, alg)
    material = :public_key.pem_decode(pem) |> List.first |> :public_key.pem_entry_decode
    {:ok, material}
  end

  defp get_privkey_pem(:ephemeral, alg), do: generate_privkey_pem!(alg)
  defp get_privkey_pem({:dir, privkey_dir}, alg) do
    privkey_path = Path.join(privkey_dir, "ssh_host_#{alg}_key")
    unless File.exists?(privkey_path) do
      File.mkdir_p!(privkey_dir)
      System.cmd("ssh-keygen", ["-q", "-t", alg, "-P", "", "-f", privkey_path])
    end

    File.read!(privkey_path)
  end

  defp generate_privkey_pem!(alg) do
    work_dir = Temp.mkdir!
    privkey_path = Path.join(work_dir, "ssh_host_#{alg}_key")
    {_, 0} = System.cmd "ssh-keygen", ["-q", "-t", alg, "-P", "", "-f", privkey_path]
    pem = File.read!(privkey_path)
    File.rm_rf!(work_dir)
    pem
  end

  defp validate_key_for_user(user, key) do
    GenServer.call(__MODULE__, {:authenticate, user, key})
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
    backend = Application.get_env(:exuvia, :auth, Exuvia.KeyBag.Dummy)
    {:ok, %{backend: backend, cache: Exuvia.AuthResponseCache.new}}
  end

  def terminate(_reason, _state), do: :ok

  def handle_call(:reset, state) do
    {:reply, :ok, %{state | cache: Exuvia.AuthResponseCache.new}}
  end

  def handle_call({:authenticate, username, material}, _, %{cache: arc, backend: backend} = state) do
    {arc, cached_resp} = Exuvia.AuthResponseCache.by_request(arc, {username, material})
    if cached_resp do
      {:reply, cached_resp.granted, %{state | cache: arc}}
    else
      {granted, ttl} = backend.auth_request(username, material)
      arc = Exuvia.AuthResponseCache.insert(arc, %Exuvia.AuthResponse{username: username, material: material, granted: granted, ttl: ttl})
      {:reply, granted, %{state | cache: arc}}
    end
  end
end
