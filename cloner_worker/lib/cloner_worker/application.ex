defmodule ClonerWorker.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  import Supervisor.Spec

  @impl true
  def start(_type, _args) do
    consumer_group_opts = []
    todo_consumer = ClonerWorker.TodoChunkConsumer
    topic_names = ["todo-chunks"]

    children = [
      {Registry, [keys: :unique, name: ClonerWorker.MyRegistry]},
      {ClonerWorker.WorkerManager, []},
      {ClonerWorker.Queue, []},
      {ClonerWorker.WorkerDynamicSupervisor, []},
      {Task, &ClonerWorker.WorkerDynamicSupervisor.start_workers/0},
      {ClonerWorker.RateLimiter, []},
      supervisor(
        KafkaEx.ConsumerGroup,
        [todo_consumer, "todo-chunks-consumer-group", topic_names, consumer_group_opts]
      )
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ClonerWorker.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
