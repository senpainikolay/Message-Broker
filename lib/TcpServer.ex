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
    {:ok, pid} = Task.Supervisor.start_child(conSupervisor, fn -> ConnectionClient.authenticate(client,cmds) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket, conSupervisor,cmds)
  end
end
