defmodule MessageBroker do
  use Application

  @impl true
  def start(_type,_args) do
    children = [
          %{
            id: :TcpServerConnectionPoolSupervisor,
            start: {ConnectionSupervisor, :start,  [] },
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
          %{
            id: :DeadLetterChannel,
            start: {DeadLetterChannel, :start,  [] },
            type: :worker
          },
      ]
    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end
end
