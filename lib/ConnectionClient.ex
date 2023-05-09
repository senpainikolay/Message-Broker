defmodule ConnectionClient do
    def serve(socket,cmds) do
      socket
      |> read_line()
      |> process_data(cmds)
      |> write_line(socket)
      check_queue(socket)
      serve(socket,cmds)
    end

    defp read_line(socket) do
      {:ok, data} = :gen_tcp.recv(socket, 0)
      cond do
        data == "\r\n" -> "lorem lipsum"
        true -> data
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

    defp process_data(data,cmds) do
     splitted = String.split(data)
     b = Enum.member?(cmds,elem(List.to_tuple(splitted),0))
     cond do
      b == true ->
        send(ChannelManager,{data,self()});
        receive do
          msg -> msg
        end
      true -> "wrong command!\r\n>"
     end
    end
end
