defmodule Exuvia.KeyBag.POSIX do
  @moduledoc ~S"""
  A strategy for authenticating SSH keys against the filesystem;
  replicates the default behavior of the SSH daemon
  """

  defstruct user_sieve: nil

  def init([]) do
    # allow in any user that has an authorized_keys file on the local filesystem
    {:ok, %__MODULE__{user_sieve: fn(_) -> true end}}
  end
  def init([allowed_user: allowed_user]) when is_binary(allowed_user) do
    {:ok, %__MODULE__{user_sieve: &(&1 == allowed_user)}}
  end

  def auth_request(req_username, req_material, state) do
    if :ssh_file.is_auth_key(req_material, String.to_charlist(req_username), []) do
      authorize(req_username, state)
    else
      {false, 60, state}
    end
  end

  def authorize(req_username, %__MODULE__{user_sieve: sieve_fn} = state) do
    {sieve_fn.(req_username), 60, state}
  end
end
