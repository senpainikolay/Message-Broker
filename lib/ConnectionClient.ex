defmodule ConnectionClient do
    def serve(socket,cmds) do
      socket
      |> read_line()
      |> process_data(cmds)
      |> write_line(socket)
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
