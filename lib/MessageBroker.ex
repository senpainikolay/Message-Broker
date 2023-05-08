defmodule MessageBroker do
  use Supervisor

  def start() do
    children = [
          %{
            id: :TcpServerConnectionPoolSupervisor,
            start: {TcpServer.ConnectionSupervisor, :start,  [] },
            type: :supervisor
          },
          %{
            id: :ChannelSupervisor,
            start: {ChannelSupervisor, :start,  [] },
            type: :supervisor
          },
          %{
            id: :ChannelManager,
            start: {ChannelManager, :start,  [] },
            type: :worker
          },

      ]
    Supervisor.start_link(__MODULE__, children, name: __MODULE__)
  end
  def init(children) do
    Supervisor.init(children, strategy: :one_for_one,  max_restarts: 10, max_seconds: 10 )
  end
end
