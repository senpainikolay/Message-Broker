defmodule TcpServer.ConnectionSupervisor do
  use Supervisor

  def start() do
    cmd1 = ["GET", "CREATE", "PUBLISH"]
    cmd2 = ["GET", "SUBSCRIBE","UNSUBSCRIBE"]
    children =
      [
      {Task.Supervisor, name: PublisherConnectionsSupervisor},
      {Task.Supervisor, name: ConsumerConnectionsSupervisor},
      Supervisor.child_spec({Task, fn -> TcpServer.accept(4000,PublisherConnectionsSupervisor,cmd1) end}, restart: :permanent, id: :PublisherServer ),
      Supervisor.child_spec({Task, fn -> TcpServer.accept(4001,ConsumerConnectionsSupervisor,cmd2) end}, restart: :permanent, id: :ConsumerServer)
      ]
    Supervisor.start_link(__MODULE__, children, name: __MODULE__)
  end
  def init(children) do
    Supervisor.init(children, strategy: :one_for_one,  max_restarts: 10, max_seconds: 10 )
  end
end
