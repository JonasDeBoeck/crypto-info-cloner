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
    topic_names = ["todo-tasks"]
    children = [
      {ChunkCreator.Repo, []},
      supervisor(
        KafkaEx.ConsumerGroup,
        [todo_consumer, "todo-tasks-consumer-group", topic_names, consumer_group_opts]
      )
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ChunkCreator.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
