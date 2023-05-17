defmodule DeadLetterChannel do
  use GenServer
  def start() do
    GenServer.start_link(__MODULE__ , [], name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_info(msg, state) do
    state = state ++ [[msg]]
    {:noreply, state}
  end

end
