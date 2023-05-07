defmodule TcpServer do
  require Logger

  def accept(port, conSupervisor,cmds) do
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(socket, conSupervisor,cmds)
  end

  defp loop_acceptor(socket, conSupervisor,cmds) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(conSupervisor, fn -> serve(client,cmds) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket, conSupervisor,cmds)
  end

  defp serve(socket,cmds) do
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
    b == true -> "kek\n"
    true -> "wrong command!\r\n"
   end
  end
end
