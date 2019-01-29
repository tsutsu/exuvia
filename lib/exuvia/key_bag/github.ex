defmodule Exuvia.KeyBag.Github do
  @moduledoc ~S"""
  A strategy for authenticating SSH keys against a Github user's public keys
  """

  # require Logger

  # defstruct allowed_organizations: MapSet.new(), client: nil

  def init(_), do: raise("broken")

  def auth_request(_, _, _), do: raise("broken")

  # def init(opts) when is_list(opts), do: init(Enum.into(opts, %{}))

  # def init(%{allowed_organizations: orgs, access_token: token})
  #     when is_binary(token) and byte_size(token) == 40 do
  #   {:ok,
  #    %__MODULE__{
  #      allowed_organizations: MapSet.new(orgs),
  #      client: Tentacat.Client.new(%{access_token: token})
  #    }}
  # end

  # def auth_request(req_username, req_material, %__MODULE__{client: client} = state) do
  #   match_materials =
  #     Tentacat.Users.Keys.list(req_username, client)
  #     |> Enum.map(& &1["key"])
  #     |> Enum.join("\n")
  #     |> :public_key.ssh_decode(:public_key)
  #     |> Enum.map(&elem(&1, 0))
  #     |> MapSet.new()

  #   if MapSet.member?(match_materials, req_material) do
  #     authorize(req_username, state)
  #   else
  #     {false, 3600, state}
  #   end
  # end

  # defp authorize(
  #        req_username,
  #        %__MODULE__{client: client, allowed_organizations: match_orgs} = state
  #      ) do
  #   req_orgs =
  #     Tentacat.Organizations.list(req_username, client)
  #     |> Enum.map(& &1["login"])
  #     |> MapSet.new()

  #   overlap = MapSet.intersection(req_orgs, match_orgs)

  #   {MapSet.size(overlap) > 0, 3600, state}
  # end
end
