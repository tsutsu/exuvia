defmodule Exuvia do
  @moduledoc ~S"""
  """

  require Logger

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Exuvia.Daemon, []),
      worker(Exuvia.KeyBag, []),
    ]

    opts = [
      name: Exuvia.Supervisor,
      strategy: :one_for_one
    ]

    Supervisor.start_link(children, opts)
  end
end
