defmodule ChannelManager do
  use GenServer
  def start() do
    GenServer.start_link(__MODULE__ , %{}, name: __MODULE__ )
  end

  def init(state) do
    {:ok, state}
  end

  def handle_info({cmd, pid, pidAuthName} , state) do
    state = Map.put(state,pid,pidAuthName)
    splitted = String.split(cmd)
    [whichCmd|t] =  splitted
    cond do
      whichCmd == "CREATE" ->
        parse_CREATE(t,pid)
        {:noreply, state}
      whichCmd == "GET" ->
        parse_GET(pid)
        {:noreply, state}
      whichCmd == "PUBLISH" ->
        parse_PUBLISH(t,pid,state)
        {:noreply, state}
      whichCmd == "SUBSCRIBE" ->
        parse_SUBSCRIBE(t,pid)
        {:noreply, state}
      whichCmd == "UNSUBSCRIBE" ->
        parse_UNSUBSCRIBE(t,pid)
        {:noreply, state}
      true ->   {:noreply, state}
    end
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

  defp parse_PUBLISH(t,pid,state) do
    [chnl | msg] = t
    cond do
      containsChannel(chnl) == true ->
             send(pid, publish_messages_to_cosumers(chnl, msg,state))
      true -> send(pid,"Channel 404\r\n>")
    end
  end

  defp publish_messages_to_cosumers(chnl,msg,state) do
     GenServer.call(String.to_atom(chnl), {:update,msg})
     subs = GenServer.call(String.to_atom(chnl), :get_subscribers)
     cond do
      length(subs) > 0 ->
         strMsg = Enum.reduce(msg, "", fn x,acc -> acc <> " "  <> x end )
         fnMsg = "\r\n The message from channel "  <> chnl <> ":\r\n" <> strMsg <> "\r\n"
         reached = Enum.reduce(subs, 0, fn sub,acc -> acc +
          cond do
            Process.alive?(sub) == true ->
              send(sub, fnMsg)
              1
            true ->
              {:ok,pid} = Database.start_link
              kek = Database.toMap([Map.get(state, sub), fnMsg ])
              Database.post(kek, pid)
              0
          end
        end)
       "Reached out " <> Integer.to_string(reached) <> " out of " <> Integer.to_string(length(subs)) <> "\r\n>"
      true -> "0 subscribers\r\n>"
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
