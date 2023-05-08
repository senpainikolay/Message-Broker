defmodule ChannelManager do
  use GenServer
  def start() do
    GenServer.start_link(__MODULE__ , %{}, name: __MODULE__ )
  end

  def init(state) do
    {:ok, state}
  end

  def handle_info({cmd, pid} , state) do
    splitted = String.split(cmd)
    [whichCmd|t] =  splitted
    cond do
      whichCmd == "CREATE" ->
        parse_CREATE(t,pid)
      whichCmd == "GET" ->
        parse_GET(pid)
    end

    {:noreply, state}
  end

  defp parse_CREATE([channelName],pid) do
    Supervisor.start_child( ChannelSupervisor,
      %{
        id: String.to_atom(channelName),
        start: {Channel, :start,  [String.to_atom(channelName)] },
        type: :worker
      })
      send(pid, "created\r\n\n>")
  end

  defp parse_GET(to_pid) do
    chnlsString =
    Enum.reduce(Supervisor.which_children(ChannelSupervisor), [], fn x,acc -> {name,_,_,_} = x;  acc ++ [name] end )
    |> Enum.reduce("\r\n\nCurrent Channels:\r\n", fn x, acc -> acc <> " " <> Atom.to_string(x) <> "\r\n" end)
    send(to_pid,chnlsString <> "\r\n\n>")

  end

  # defp get_channels do
  #   chnls = Supervisor.which_children(ChannelSupervisor)

  # end

end
