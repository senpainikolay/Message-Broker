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
      whichCmd == "PUBLISH" ->
        parse_PUBLISH(t,pid)
      whichCmd == "SUBSCRIBE" ->
        parse_SUBSCRIBE(t,pid)
      whichCmd == "UNSUBSCRIBE" ->
        parse_UNSUBSCRIBE(t,pid)
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

  defp parse_PUBLISH(t,pid) do
    [chnl | msg] = t
    cond do
      containsChannel(chnl) == true ->
             send(pid, GenServer.call(String.to_atom(chnl), {:update,msg}))
             publish_messages_to_cosumers(chnl, msg)
      true -> send(pid,"Channel 404\r\n>")
    end
  end

  defp publish_messages_to_cosumers(chnl,msg) do
     subs = GenServer.call(String.to_atom(chnl), :get_subscribers)
     cond do
      length(subs) > 0 ->
         strMsg = Enum.reduce(msg, "", fn x,acc -> acc <> " "  <> x end )
         Enum.each(subs, fn sub -> send(sub, "\r\n The message from channel "  <> chnl <> ":\r\n" <> strMsg <> "\r\n" )end);
      true -> :ok
     end
  end


  defp parse_SUBSCRIBE([channelName],pid) do
    cond do
      containsChannel(channelName) == true ->  send(pid, GenServer.call(String.to_atom(channelName), {:subscribe,pid}))
      true -> send(pid,"Channel 404\r\n>")
    end
  end

  defp parse_UNSUBSCRIBE([channelName],pid) do
    cond do
      containsChannel(channelName) == true ->  send(pid, GenServer.call(String.to_atom(channelName), {:unsubscribe,pid}))
      true -> send(pid,"Channel 404\r\n>")
    end
  end

  defp parse_GET(to_pid) do
    chnlsString =
    Enum.reduce(Supervisor.which_children(ChannelSupervisor), [], fn x,acc -> {name,_,_,_} = x;  acc ++ [name] end )
    |> Enum.reduce("\r\n\nCurrent Channels:\r\n", fn x, acc -> acc <> " " <> Atom.to_string(x) <> "\r\n" end)
    send(to_pid,chnlsString <> "\r\n\n>")

  end

  defp  containsChannel(chnl) do
    Enum.reduce(Supervisor.which_children(ChannelSupervisor), [], fn x,acc -> {name,_,_,_} = x;  acc ++ [name] end )
    |> Enum.member?(String.to_atom(chnl))
  end

end
