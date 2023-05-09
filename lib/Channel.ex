defmodule Channel do
  use GenServer

  def start(name) do
    GenServer.start_link(__MODULE__ , %{}, name: name )
  end

  def init(state) do
    state = Map.put(state, "messages",[])
    state = Map.put(state, "subscribers",[])
    {:ok, state}
  end
  def handle_call({:update, msg}, _from, state) do
    strMsg = Enum.reduce(msg, "", fn x,acc -> acc <> " "  <> x end )
    state = Map.update!(state, "messages", &(&1 ++ [[strMsg]]))
    {:reply,"message received to Broker\r\n>", state}
  end

  def handle_call({:subscribe, client}, _from, state) do
    state = Map.update!(state, "subscribers", &(&1 ++ [client]))
    IO.inspect(state)
    {:reply,"subscribed\r\n>", state}
  end

  def handle_call({:unsubscribe, client}, _from, state) do
    newSubs =
    Map.get(state, "subscribers")
    |> Enum.filter(fn x -> x != client end)
    state = Map.replace(state,"subscribers", newSubs)
    IO.inspect(state)
    {:reply,"usubscribed\r\n>", state}
  end

  def handle_call(:get_subscribers, _from, state) do
    subs = Map.get(state, "subscribers")
    {:reply,subs, state}
  end

end
