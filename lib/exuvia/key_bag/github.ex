defmodule Exuvia.KeyBag.Github do
  @moduledoc ~S"""
  A strategy for authenticating SSH keys against a Github user's public keys
  """

  def auth_request(req_username, req_material) do
    access_token = System.get_env("GITHUB_ACCESS_TOKEN")
    authenticate(req_username, req_material, access_token)
  end

  defp authenticate(_, _, nil), do: {false, :infinity}
  defp authenticate(req_username, req_material, access_token) do
    client = Tentacat.Client.new(%{access_token: access_token})
    ssh_keys = query_github_keys_for_user!(req_username, client)
    ssh_materials = ssh_keys
      |> Enum.join("\n")
      |> :public_key.ssh_decode(:public_key)
      |> Enum.map(&(elem(&1, 0)))
      |> MapSet.new

    if MapSet.member?(ssh_materials, req_material) do
      authorize(req_username, client)
    else
      {false, 3600}
    end
  end

  defp authorize(req_username, client) do
    req_orgs = Tentacat.Organizations.list(req_username, client) |> Enum.map(&(&1["login"])) |> MapSet.new
    match_orgs = (System.get_env("GITHUB_AUTHORIZED_ORGS") || "") |> String.split(",") |> MapSet.new
    overlap = MapSet.intersection(req_orgs, match_orgs)
    {(MapSet.size(overlap) > 0), 3600}
  end

  defp query_github_keys_for_user!(github_username, client) do
    Tentacat.Users.Keys.list(github_username, client) |> Enum.map(&(&1["key"]))
  end
end
