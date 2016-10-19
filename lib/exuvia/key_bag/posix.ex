defmodule Exuvia.KeyBag.POSIX do
  @moduledoc ~S"""
  A strategy for authenticating SSH keys against the filesystem;
  replicates the default behavior of the SSH daemon
  """

  def auth_request(req_username, req_material) do
    granted = :ssh_file.is_auth_key(req_material, String.to_char_list(req_username), [])
    {granted, 60}
  end
end
