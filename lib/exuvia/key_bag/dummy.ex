defmodule Exuvia.KeyBag.Dummy do
  @moduledoc ~S"""
  A trivial strategy for either always, or never, authenticating SSH keys
  """

  def init([allow: :always]), do: {:ok, true}
  def init([allow: :never]), do: {:ok, false}

  def auth_request(_, _, true), do: {true, :infinity, true}
  def auth_request(_, _, false), do: {false, :infinity, false}
end
