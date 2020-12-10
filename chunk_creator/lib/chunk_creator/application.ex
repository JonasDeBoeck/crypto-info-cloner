defmodule ChunkCreator.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  import Supervisor.Spec

  @impl true
  def start(_type, _args) do
    consumer_group_opts = []
    todo_consumer = ChunkCreator.TodoTaskConsumer
    finished_consumer = ChunkCreator.CompletedChunkConsumer
    todo_topic = ["todo-tasks"]
    finished_topic = ["finished-chunks"]

    children = [
      {ChunkCreator.Repo, []},
      %{
        id: TodoTasksConsumerGroup,
        start:
          {KafkaEx.ConsumerGroup, :start_link,
           [todo_consumer, "todo-tasks-consumer-group", todo_topic, consumer_group_opts]}
      },
      %{
        id: FinishedChunksConsumerGroup,
        start:
          {KafkaEx.ConsumerGroup, :start_link,
           [
             finished_consumer,
             "finished-chunks-consumer-group",
             finished_topic,
             consumer_group_opts
           ]}
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ChunkCreator.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
