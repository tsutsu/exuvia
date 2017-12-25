defmodule Exuvia.SessionCounter do
  use Agent

  def start_link do
    Agent.start_link(fn -> 0 end, name: __MODULE__)
  end

  def take_next do
    Agent.get_and_update(__MODULE__, fn(prev) ->
      curr = prev + 1
      {curr, curr}
    end)
  end
end
