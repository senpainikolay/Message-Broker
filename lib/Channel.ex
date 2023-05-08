defmodule Channel do
  use GenServer

  def start(name) do
    GenServer.start_link(__MODULE__ , [[]], name: name )
  end

  def init(state) do
    {:ok, state}
  end


  def heandle_info(msg,  state) do
    state = state ++ [[msg]]
    {:noreply, state}
  end

end
