defmodule Exuvia.KeyBag.Dummy do
  @moduledoc ~S"""
  A strategy for authenticating SSH keys that always succeeds
  """

  def auth_request(_, _) do
    {true, :infinity}
  end
end
