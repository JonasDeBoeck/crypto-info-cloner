defmodule ClonerWorker.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    consumer_group_opts = []
    todo_consumer = ClonerWorker.TodoChunkConsumer
    topic_names = ["todo-chunks"]

    children = [
      {Registry, [keys: :unique, name: ClonerWorker.MyRegistry]},
      {ClonerWorker.Queue, []},
      {ClonerWorker.WorkerDynamicSupervisor, []},
      {ClonerWorker.WorkerManager, []},
      {ClonerWorker.RateLimiter, []},
      %{
        id: TodoChunksConsumerGroup,
        start:
          {KafkaEx.ConsumerGroup, :start_link,
          [todo_consumer, "todo-chunks-consumer-group", topic_names, consumer_group_opts]}
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_all, name: ClonerWorker.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
