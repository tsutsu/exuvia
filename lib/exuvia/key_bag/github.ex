defmodule Exuvia.KeyBag.Github do
  @moduledoc ~S"""
  A strategy for authenticating SSH keys against a Github user's public keys
  """

  require Logger

  defstruct acl: nil, client: nil

  def auth_opts([orgs, token])
      when is_binary(orgs) and is_binary(token) and byte_size(token) == 40 do
    pubkey_opts = %__MODULE__{
      acl: orgs |> URI.decode() |> Ghauth.acl(),
      client: Ghauth.Client.new(%{access_token: token})
    }

    [
      publickey_backend: {__MODULE__, pubkey_opts},
      password: String.to_charlist(token)
    ]
  end

  def init(%__MODULE__{} = s) do
    {:ok, s}
  end

  def auth_request(req_username, req_material, %__MODULE__{client: client} = state) do
    if Ghauth.match_key?(req_username, req_material, client) do
      authorize(req_username, state)
    else
      {false, 3600, state}
    end
  end

  defp authorize(req_username, %__MODULE__{} = state) do
    match = Ghauth.match?(req_username, state.acl, state.client)
    {match, 3600, state}
  end
end
