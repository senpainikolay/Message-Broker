defmodule ConnectionClient do


   def authenticate(socket,cmds) do
      :gen_tcp.send(socket,"Please introduce yourself:\r\n>" )
      {status, data } = :gen_tcp.recv(socket,0)
      cond do
        status == :ok ->
          validate_auth_input(socket,cmds,data)
          |> serve(socket,cmds)
        status == :error -> IO.inspect("lost connection")
      end
   end

   def validate_auth_input(socket, cmds, str) do
    splitted =  String.split(str)
    if length(splitted) != 3 do
      :gen_tcp.send(socket,"Smth wong...\r\n>" )
      authenticate(socket,cmds)
    end
    [h|t ] = splitted
    if h != "I" do
      :gen_tcp.send(socket,"Smth wong...\r\n>" )
      authenticate(socket,cmds)
    end
    [h | t] = t
    if h != "AM" do
      :gen_tcp.send(socket,"Smth wong...\r\n>" )
      authenticate(socket,cmds)
    end
    [h | _] = t
    :gen_tcp.send(socket, "Welcome " <> h <> "! \r\n>" )
    {:ok,pid} = Database.start_link
    kek = Tds.query!(pid, "SELECT * FROM messages WHERE name = '#{h}'",[])
    cond do
      length(kek.rows) > 0 ->
        :gen_tcp.send(socket, "Heres msgs for " )
        Enum.each(kek.rows, fn r ->
          :gen_tcp.send(socket, "\r\n" <> List.to_string(r) <> "\r\n")
        end  )
        Database.delete(h,pid)
      true ->h
    end
   end



    def serve(name,socket,cmds) do
      socket
      |> read_line()
      |> process_data(cmds,name)
      |> write_line(socket)
      check_queue(socket)
      serve(name,socket,cmds)
    end

    defp read_line(socket) do
      {status, data } = :gen_tcp.recv(socket,0)
      cond do
        status == :ok ->
          cond do
            data == "\r\n" -> "lorem lipsum"
            true -> data
          end
        status == :error -> IO.inspect("LOst connection"); Process.exit(self(), :kill)
      end
    end

    defp write_line(line, socket) do
      :gen_tcp.send(socket, line)
    end

    defp check_queue(socket) do
      {_, nr} =  Process.info(self(), :message_queue_len)
      cond do
        nr > 0 -> read_publisher_messages(nr,socket)
        true -> :ok
      end
    end

    defp read_publisher_messages(nr,socket) do
      cond do
        nr > 0 ->
          receive do
            msg -> :gen_tcp.send(socket, msg)
            read_publisher_messages(nr-1,socket)
          end
        nr <= 0 -> :ok
      end
    end

    defp process_data(data,cmds,name) do
     splitted = String.split(data)
     b = Enum.member?(cmds,elem(List.to_tuple(splitted),0))
     cond do
      b == true ->
        send(ChannelManager,{data,self(),name});
        receive do
          msg -> msg
        after
          3000 -> send(DeadLetterChannel, data)
        end
      true -> "wrong command!\r\n>"
     end
    end
end
