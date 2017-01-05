defmodule Exuvia.AuthResponseCache do
  defstruct serial: 0, items: Map.new, by_username: Map.new, by_request: Map.new

  defmodule CacheItem do
    defstruct id: 0, expire_time: 0, response: nil
  end

  def new do
    %__MODULE__{}
  end

  def insert(%__MODULE__{} = t, %Exuvia.AuthResponse{} = new_response) do
    item_id = t.serial + 1

    expire_time = case new_response.ttl do
      n when is_number(n) ->
        :erlang.monotonic_time(:seconds) + n
      :infinity ->
        # an arbitrary binary. ∀xy(integer(x) < binary(y)), so
        # a binary taken as a timestamp will never "pass by"
        "infinity"
    end

    item = %CacheItem{id: item_id, expire_time: expire_time, response: new_response}
    items_set = Map.put(t.items, item_id, item)

    username_index = Map.update(t.by_username, new_response.username, MapSet.new([item_id]), &(MapSet.put(&1, item_id)))
    request_index = Map.put(t.by_request, {new_response.username, new_response.material}, item_id)

    %{t | serial: item_id, items: items_set, by_username: username_index, by_request: request_index}
  end

  def delete(%__MODULE__{} = t, item) do
    items_set = Map.delete(t.items, item.id)

    username_index = Map.update(t.by_username, item.response.username, MapSet.new, &(MapSet.delete(&1, item.response.username)))
    request_index = Map.delete(t.by_request, {item.response.username, item.response.material})

    %{t | items: items_set, by_username: username_index, by_request: request_index}
  end

  def by_request(%__MODULE__{items: items_set, by_request: request_index} = t, request) do
    item_id = Map.get(request_index, request)

    if item_id do
      item = Map.fetch!(items_set, item_id)
      {t, survived_items} = expire(t, [item])
      survived_resps = Enum.map(survived_items, &(&1.response))
      {t, List.first(survived_resps)}
    else
      {t, nil}
    end
  end

  def all_by_username(%__MODULE__{items: items_set, by_username: username_index} = t, username) do
    item_ids = Map.get(username_index, username, [])
    items = item_ids |> Enum.map(&(Map.fetch!(items_set, &1)))
    {t, survived_items} = expire(t, items)
    survived_resps = Enum.map(survived_items, &(&1.response))
    {t, survived_resps}
  end

  defp expire(t, items) do
    start_time = :erlang.monotonic_time(:seconds)
    expire(t, items, [], start_time)
  end
  defp expire(t, [], survivors, _), do: {t, Enum.reverse(survivors)}
  defp expire(t, [item | items], survivors, start_time) do
    if item.expire_time <= start_time do
      expire(delete(t, item), items, survivors, start_time)
    else
      expire(t, items, [item | survivors], start_time)
    end
  end
end
